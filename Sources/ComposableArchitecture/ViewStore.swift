#if canImport(Combine)
import Combine
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
import ReactiveSwift

@dynamicMemberLookup
public final class ViewStore<State, Action> {
#if canImport(Combine)
  @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
  public private(set) lazy var objectWillChange = ObservableObjectPublisher()
#endif
  
  private let _send: (Action) -> Void
  fileprivate var _state: MutableProperty<State>
  private var viewDisposable: Disposable?
  private let (lifetime, token) = Lifetime.make()
  
  public init(
    _ store: Store<State, Action>,
    removeDuplicates isDuplicate: @escaping (State, State) -> Bool
  ) {
    self._send = { store.send($0) }
    self._state = MutableProperty(store.state.value)
    
    self.viewDisposable = store.state.producer
      .skipRepeats(isDuplicate)
      .startWithValues { [weak self] in
        guard let self = self else { return }
#if canImport(Combine)
        if #available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *) {
          self.objectWillChange.send()
          self._state.value = $0
        }
#endif
        self._state.value = $0
      }
  }
  
  public var publisher: StorePublisher<State> {
    StorePublisher(viewStore: self)
  }
  
  public var state: State {
    self._state.value
  }
  
  public func makeBindingTarget<U>(_ action: @escaping (ViewStore, U) -> Void) -> BindingTarget<U> {
    return BindingTarget(on: UIScheduler(), lifetime: lifetime) { [weak self] value in
      if let self = self {
        action(self, value)
      }
    }
  }
  
  public var action: BindingTarget<Action> {
    makeBindingTarget {
      $0.send($1)
    }
  }
  
  public subscript<LocalState>(dynamicMember keyPath: KeyPath<State, LocalState>) -> LocalState {
    self.state[keyPath: keyPath]
  }
  
  public func send(_ action: Action) {
    self._send(action)
  }
  
#if canImport(SwiftUI)
  @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
  public func binding<LocalState>(
    get: @escaping (State) -> LocalState,
    send localStateToViewAction: @escaping (LocalState) -> Action
  ) -> Binding<LocalState> {
    ObservedObject(wrappedValue: self)
      .projectedValue[get: .init(rawValue: get), send: .init(rawValue: localStateToViewAction)]
  }
  
  @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
  public func binding<LocalState>(
    get: @escaping (State) -> LocalState,
    send action: Action
  ) -> Binding<LocalState> {
    self.binding(get: get, send: { _ in action })
  }
  
  @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
  public func binding(
    send localStateToViewAction: @escaping (State) -> Action
  ) -> Binding<State> {
    self.binding(get: { $0 }, send: localStateToViewAction)
  }
  
  @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
  public func binding(send action: Action) -> Binding<State> {
    self.binding(send: { _ in action })
  }
#endif
  
  private subscript<LocalState>(
    get state: HashableWrapper<(State) -> LocalState>,
    send action: HashableWrapper<(LocalState) -> Action>
  ) -> LocalState {
    get { state.rawValue(self.state) }
    set { self.send(action.rawValue(newValue)) }
  }
  
  deinit {
    viewDisposable?.dispose()
  }
}

extension ViewStore where State: Equatable {
  public convenience init(_ store: Store<State, Action>) {
    self.init(store, removeDuplicates: ==)
  }
}

extension ViewStore where State == Void {
  public convenience init(_ store: Store<Void, Action>) {
    self.init(store, removeDuplicates: ==)
  }
}

#if canImport(Combine)
extension ViewStore: ObservableObject {
}
#endif

@dynamicMemberLookup
public struct StorePublisher<State>: SignalProducerConvertible {
  public let upstream: Effect<State, Never>
  public let viewStore: Any
  
  public var producer: Effect<State, Never> {
    upstream
  }
  
  fileprivate init<Action>(viewStore: ViewStore<State, Action>) {
    self.viewStore = viewStore
    self.upstream = viewStore._state.producer
  }
  
  private init(upstream: Effect<State, Never>,viewStore: Any) {
    self.upstream = upstream
    self.viewStore = viewStore
  }
  
  public subscript<LocalState>(dynamicMember keyPath: KeyPath<State, LocalState>) -> StorePublisher<LocalState> where LocalState: Equatable {
    .init(upstream: self.upstream.map(keyPath).skipRepeats(), viewStore: self.viewStore)
  }
}

private struct HashableWrapper<Value>: Hashable {
  let rawValue: Value
  static func == (lhs: Self, rhs: Self) -> Bool { false }
  func hash(into hasher: inout Hasher) {}
}
