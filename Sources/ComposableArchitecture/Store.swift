import Foundation
import ReactiveSwift

public final class Store<State, Action> {
  private var bufferedActions: [Action] = []
  var effectDisposables: [UUID: Disposable] = [:]
  private var isSending = false
  var parentDisposable: Disposable?
  private let reducer: (inout State, Action) -> Effect<Action, Never>
  var state: MutableProperty<State>
  #if DEBUG
    private let mainThreadChecksEnabled: Bool
  #endif
  
  public convenience init<Environment>(
    initialState: State,
    reducer: Reducer<State, Action, Environment>,
    environment: Environment
  ) {
    self.init(
      initialState: initialState,
      reducer: reducer,
      environment: environment,
      mainThreadChecksEnabled: true
    )
    self.threadCheck(status: .`init`)
  }
  
  public static func unchecked<Environment>(
    initialState: State,
    reducer: Reducer<State, Action, Environment>,
    environment: Environment
  ) -> Self {
    Self(
      initialState: initialState,
      reducer: reducer,
      environment: environment,
      mainThreadChecksEnabled: false
    )
  }
  
  public func scope<LocalState, LocalAction>(
    state toLocalState: @escaping (State) -> LocalState,
    action fromLocalAction: @escaping (LocalAction) -> Action
  ) -> Store<LocalState, LocalAction> {
    var isSending = false
    let localStore = Store<LocalState, LocalAction>(
      initialState: toLocalState(self.state.value),
      reducer: .init { localState, localAction, _ in
        isSending = true
        defer { isSending = false }
        self.send(fromLocalAction(localAction))
        localState = toLocalState(self.state.value)
        return .none
      },
      environment: ()
    )
    
    localStore.parentDisposable = self.state.producer
      .skip(first: 1)
      .startWithValues { [weak localStore] newValue in
        guard !isSending else { return }
        localStore?.state.value = toLocalState(newValue)
      }
    
    return localStore
  }
  
  public func scope<LocalState>(
    state toLocalState: @escaping (State) -> LocalState
  ) -> Store<LocalState, Action> {
    self.scope(state: toLocalState, action: { $0 })
  }
  
  func send(_ action: Action, originatingFrom originatingAction: Action? = nil) {
    self.threadCheck(status: .send(action, originatingAction: originatingAction))
    self.bufferedActions.append(action)
    guard !self.isSending else { return }
    self.isSending = true
    var currentState = self.state.value
    defer {
      self.isSending = false
      self.state.value = currentState
    }
    while !self.bufferedActions.isEmpty {
      let action = self.bufferedActions.removeFirst()
      let effect = self.reducer(&currentState, action)
      var didComplete = false
      let uuid = UUID()
      let observer = Signal<Action, Never>.Observer(
        value: { [weak self] effectAction in
          self?.send(effectAction, originatingFrom: action)
        },
        completed: { [weak self] in
          self?.threadCheck(status: .effectCompletion(action))
          didComplete = true
          self?.effectDisposables.removeValue(forKey: uuid)?.dispose()
        },
        interrupted: { [weak self] in
          didComplete = true
          self?.effectDisposables.removeValue(forKey: uuid)?.dispose()
        }
      )
      let effectDisposable = effect.start(observer)
      if !didComplete {
        self.effectDisposables[uuid] = effectDisposable
      }
    }
  }
  
  public var stateless: Store<Void, Action> {
    self.scope(state: { _ in () })
  }
  
  public var actionless: Store<State, Never> {
    func absurd<A>(_ never: Never) -> A {}
    return self.scope(state: { $0 }, action: absurd)
  }
  
  deinit {
    self.parentDisposable?.dispose()
    self.effectDisposables.keys.forEach { id in
      self.effectDisposables.removeValue(forKey: id)?.dispose()
    }
  }
  private enum ThreadCheckStatus {
    case effectCompletion(Action)
    case `init`
    case scope
    case send(Action, originatingAction: Action?)
  }

  @inline(__always)
  private func threadCheck(status: ThreadCheckStatus) {
    #if DEBUG
      guard self.mainThreadChecksEnabled && !Thread.isMainThread
      else { return }

      let message: String
      switch status {
      case let .effectCompletion(action):
        message = """
          An effect returned from the action "\(debugCaseOutput(action))" completed on a non-main \
          thread. Make sure to use ".receive(on:)" on any effects that execute on background \
          threads to receive their output on the main thread, or create this store via \
          "Store.unchecked" to disable the main thread checker.
          """

      case .`init`:
        message = """
          "Store.init" was called on a non-main thread. Make sure that stores are initialized on \
          the main thread, or create this store via "Store.unchecked" to disable the main thread \
          checker.
          """

      case .scope:
        message = """
          "Store.scope" was called on a non-main thread. Make sure that "Store.scope" is always \
          called on the main thread, or create this store via "Store.unchecked" to disable the \
          main thread checker.
          """

      case let .send(action, originatingAction: nil):
        message = """
          "ViewStore.send(\(debugCaseOutput(action)))" was called on a non-main thread. Make sure \
          that "ViewStore.send" is always called on the main thread, or create this store via \
          "Store.unchecked" to disable the main thread checker.
          """

      case let .send(action, originatingAction: .some(originatingAction)):
        message = """
          An effect returned from "\(debugCaseOutput(originatingAction))" emitted the action \
          "\(debugCaseOutput(action))" on a non-main thread. Make sure to use ".receive(on:)" on \
          any effects that execute on background threads to receive their output on the main \
          thread, or create this store via "Store.unchecked" to disable the main thread checker.
          """
      }

      breakpoint(
        """
        ---
        Warning:

        A store created on the main thread was interacted with on a non-main thread:

          Thread: \(Thread.current)

        \(message)

        The "Store" class is not thread-safe, and so all interactions with an instance of "Store" \
        (including all of its scopes and derived view stores) must be done on the main thread.
        ---
        """
      )
    #endif
  }
  
  private init<Environment>(
    initialState: State,
    reducer: Reducer<State, Action, Environment>,
    environment: Environment,
    mainThreadChecksEnabled: Bool
  ) {
    self.state = MutableProperty(initialState)
    self.reducer = { state, action in reducer.run(&state, action, environment) }
    #if DEBUG
      self.mainThreadChecksEnabled = mainThreadChecksEnabled
    #endif
  }
}