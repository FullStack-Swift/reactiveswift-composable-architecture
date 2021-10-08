#if canImport(SwiftUI)
  import CasePaths

  import SwiftUI

  // NB: Deprecated after 0.25.0:

  #if compiler(>=5.4)
    extension BindingAction {
      @available(
        *, deprecated,
        message:
          "For improved safety, bindable properties must now be wrapped explicitly in 'BindableState', and accessed via key paths to that 'BindableState', like '\\.$value'"
      )
      public static func set<Value>(
        _ keyPath: WritableKeyPath<Root, Value>,
        _ value: Value
      ) -> Self
      where Value: Equatable {
        .init(
          keyPath: keyPath,
          set: { $0[keyPath: keyPath] = value },
          value: value,
          valueIsEqualTo: { $0 as? Value == value }
        )
      }

      @available(
        *, deprecated,
        message:
          "For improved safety, bindable properties must now be wrapped explicitly in 'BindableState', and accessed via key paths to that 'BindableState', like '\\.$value'"
      )
      public static func ~= <Value>(
        keyPath: WritableKeyPath<Root, Value>,
        bindingAction: Self
      ) -> Bool {
        keyPath == bindingAction.keyPath
      }
    }

    extension Reducer {
      @available(
        *, deprecated,
        message:
          "'Reducer.binding()' no longer takes an explicit extract function and instead the reducer's 'Action' type must conform to 'BindableAction'"
      )
      public func binding(action toBindingAction: @escaping (Action) -> BindingAction<State>?)
        -> Self
      {
        Self { state, action, environment in
          toBindingAction(action)?.set(&state)
          return self.run(&state, action, environment)
        }
      }
    }

    #if canImport(SwiftUI)
      extension ViewStore {
        @available(
          *, deprecated,
          message:
            "For improved safety, bindable properties must now be wrapped explicitly in 'BindableState'. Bindings are now derived via dynamic member lookup to that 'BindableState' (for example, 'viewStore.$value'). For dynamic member lookup to be available, the view store's 'Action' type must also conform to 'BindableAction'."
        )
        @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
        public func binding<LocalState>(
          keyPath: WritableKeyPath<State, LocalState>,
          send action: @escaping (BindingAction<State>) -> Action
        ) -> Binding<LocalState>
        where LocalState: Equatable {
          self.binding(
            get: { $0[keyPath: keyPath] },
            send: { action(.set(keyPath, $0)) }
          )
        }
      }
    #endif
  #else
    extension BindingAction {
      @available(
        *, deprecated,
        message:
          "For improved safety, bindable properties must now be wrapped explicitly in 'BindableState', and accessed via key paths to that 'BindableState', like '\\.$value'. Upgrade to Xcode 12.5 or greater for access to 'BindableState'."
      )
      public static func set<Value>(
        _ keyPath: WritableKeyPath<Root, Value>,
        _ value: Value
      ) -> Self
      where Value: Equatable {
        .init(
          keyPath: keyPath,
          set: { $0[keyPath: keyPath] = value },
          value: value,
          valueIsEqualTo: { $0 as? Value == value }
        )
      }

      @available(
        *, deprecated,
        message:
          "For improved safety, bindable properties must now be wrapped explicitly in 'BindableState', and accessed via key paths to that 'BindableState', like '\\.$value'. Upgrade to Xcode 12.5 or greater for access to 'BindableState'."
      )
      public static func ~= <Value>(
        keyPath: WritableKeyPath<Root, Value>,
        bindingAction: Self
      ) -> Bool {
        keyPath == bindingAction.keyPath
      }
    }

    extension Reducer {
      @available(
        *, deprecated,
        message:
          "'Reducer.binding()' no longer takes an explicit extract function and instead the reducer's 'Action' type must conform to 'BindableAction'. Upgrade to Xcode 12.5 or greater for access to 'Reducer.binding()' and 'BindableAction'."
      )
      public func binding(action toBindingAction: @escaping (Action) -> BindingAction<State>?)
        -> Self
      {
        Self { state, action, environment in
          toBindingAction(action)?.set(&state)
          return self.run(&state, action, environment)
        }
      }
    }

    extension ViewStore {
      @available(
        *, deprecated,
        message:
          "For improved safety, bindable properties must now be wrapped explicitly in 'BindableState'. Bindings are now derived via dynamic member lookup to that 'BindableState' (for example, 'viewStore.$value'). For dynamic member lookup to be available, the view store's 'Action' type must also conform to 'BindableAction'. Upgrade to Xcode 12.5 or greater for access to 'BindableState' and 'BindableAction'."
      )
      public func binding<LocalState>(
        keyPath: WritableKeyPath<State, LocalState>,
        send action: @escaping (BindingAction<State>) -> Action
      ) -> Binding<LocalState>
      where LocalState: Equatable {
        self.binding(
          get: { $0[keyPath: keyPath] },
          send: { action(.set(keyPath, $0)) }
        )
      }
    }
  #endif

  // NB: Deprecated after 0.23.0:

  @available(iOS 13.0, macOS 10.15, macCatalyst 13, tvOS 13.0, watchOS 6.0, *)
  extension AlertState.Button {
    @available(*, deprecated, renamed: "cancel(_:action:)")
    public static func cancel(
      _ label: TextState,
      send action: Action?
    ) -> Self {
      Self(action: action.map(AlertState.ButtonAction.send), type: .cancel(label: label))
    }

    @available(*, deprecated, renamed: "cancel(action:)")
    public static func cancel(
      send action: Action?
    ) -> Self {
      Self(action: action.map(AlertState.ButtonAction.send), type: .cancel(label: nil))
    }

    @available(*, deprecated, renamed: "default(_:action:)")
    public static func `default`(
      _ label: TextState,
      send action: Action?
    ) -> Self {
      Self(action: action.map(AlertState.ButtonAction.send), type: .default(label: label))
    }

    @available(*, deprecated, renamed: "destructive(_:action:)")
    public static func destructive(
      _ label: TextState,
      send action: Action?
    ) -> Self {
      Self(action: action.map(AlertState.ButtonAction.send), type: .destructive(label: label))
    }
  }

  // NB: Deprecated after 0.20.0:

  extension Reducer {
    @available(*, deprecated, message: "Use the 'IdentifiedArray'-based version, instead")
    public func forEach<GlobalState, GlobalAction, GlobalEnvironment>(
      state toLocalState: WritableKeyPath<GlobalState, [State]>,
      action toLocalAction: CasePath<GlobalAction, (Int, Action)>,
      environment toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment,
      breakpointOnNil: Bool = true,
      file: StaticString = #fileID,
      line: UInt = #line
    ) -> Reducer<GlobalState, GlobalAction, GlobalEnvironment> {
      .init { globalState, globalAction, globalEnvironment in
        guard let (index, localAction) = toLocalAction.extract(from: globalAction) else {
          return .none
        }
        if index >= globalState[keyPath: toLocalState].endIndex {
          if breakpointOnNil {
            breakpoint(
              """
              ---
              Warning: Reducer.forEach@\(file):\(line)

              "\(debugCaseOutput(localAction))" was received by a "forEach" reducer at index \
              \(index) when its state contained no element at this index. This is generally \
              considered an application logic error, and can happen for a few reasons:

              * This "forEach" reducer was combined with or run from another reducer that removed \
              the element at this index when it handled this action. To fix this make sure that \
              this "forEach" reducer is run before any other reducers that can move or remove \
              elements from state. This ensures that "forEach" reducers can handle their actions \
              for the element at the intended index.

              * An in-flight effect emitted this action while state contained no element at this \
              index. While it may be perfectly reasonable to ignore this action, you may want to \
              cancel the associated effect when moving or removing an element. If your "forEach" \
              reducer returns any long-living effects, you should use the identifier-based \
              "forEach" instead.

              * This action was sent to the store while its state contained no element at this \
              index. To fix this make sure that actions for this reducer can only be sent to a \
              view store when its state contains an element at this index. In SwiftUI \
              applications, use "ForEachStore".
              ---
              """
            )
          }
          return .none
        }
        return self.run(
          &globalState[keyPath: toLocalState][index],
          localAction,
          toLocalEnvironment(globalEnvironment)
        )
        .map { toLocalAction.embed((index, $0)) }
      }
    }
  }

  @available(iOS 13, macOS 10.15, macCatalyst 13, tvOS 13, watchOS 6, *)
  extension ForEachStore {
    @available(*, deprecated, message: "Use the 'IdentifiedArray'-based version, instead")
    public init<EachContent>(
      _ store: Store<Data, (Data.Index, EachAction)>,
      id: KeyPath<EachState, ID>,
      @ViewBuilder content: @escaping (Store<EachState, EachAction>) -> EachContent
    )
    where
      Data == [EachState],
      EachContent: View,
      Content == WithViewStore<
        [ID], (Data.Index, EachAction), ForEach<[(offset: Int, element: ID)], ID, EachContent>
      >
    {
      let data = store.state.value
      self.data = data
      self.content = {
        WithViewStore(store.scope(state: { $0.map { $0[keyPath: id] } })) { viewStore in
          ForEach(Array(viewStore.state.enumerated()), id: \.element) { index, _ in
            content(
              store.scope(
                state: { index < $0.endIndex ? $0[index] : data[index] },
                action: { (index, $0) }
              )
            )
          }
        }
      }
    }

    @available(*, deprecated, message: "Use the 'IdentifiedArray'-based version, instead")
    public init<EachContent>(
      _ store: Store<Data, (Data.Index, EachAction)>,
      @ViewBuilder content: @escaping (Store<EachState, EachAction>) -> EachContent
    )
    where
      Data == [EachState],
      EachContent: View,
      Content == WithViewStore<
        [ID], (Data.Index, EachAction), ForEach<[(offset: Int, element: ID)], ID, EachContent>
      >,
      EachState: Identifiable,
      EachState.ID == ID
    {
      self.init(store, id: \.id, content: content)
    }
  }

  // NB: Deprecated after 0.17.0:

  @available(iOS 13, macOS 10.15, macCatalyst 13, tvOS 13, watchOS 6, *)
  extension IfLetStore {
    @available(*, deprecated, message: "'else' now takes a view builder closure")
    public init<IfContent, ElseContent>(
      _ store: Store<State?, Action>,
      @ViewBuilder then ifContent: @escaping (Store<State, Action>) -> IfContent,
      else elseContent: @escaping @autoclosure () -> ElseContent
    ) where Content == _ConditionalContent<IfContent, ElseContent> {
      self.init(store, then: ifContent, else: elseContent)
    }
  }

  // NB: Deprecated after 0.10.0:

  @available(iOS 13, macOS 10.15, macCatalyst 13, tvOS 13, watchOS 6, *)
  extension ActionSheetState {
    @available(*, deprecated, message: "'title' and 'message' should be 'TextState'")
    @_disfavoredOverload
    public init(
      title: LocalizedStringKey,
      message: LocalizedStringKey? = nil,
      buttons: [Button]
    ) {
      self.init(
        title: .init(title),
        message: message.map { .init($0) },
        buttons: buttons
      )
    }
  }

  @available(iOS 13, macOS 10.15, macCatalyst 13, tvOS 13, watchOS 6, *)
  extension AlertState {
    @available(*, deprecated, message: "'title' and 'message' should be 'TextState'")
    @_disfavoredOverload
    public init(
      title: LocalizedStringKey,
      message: LocalizedStringKey? = nil,
      dismissButton: Button? = nil
    ) {
      self.init(
        title: .init(title),
        message: message.map { .init($0) },
        dismissButton: dismissButton
      )
    }

    @available(*, deprecated, message: "'title' and 'message' should be 'TextState'")
    @_disfavoredOverload
    public init(
      title: LocalizedStringKey,
      message: LocalizedStringKey? = nil,
      primaryButton: Button,
      secondaryButton: Button
    ) {
      self.init(
        title: .init(title),
        message: message.map { .init($0) },
        primaryButton: primaryButton,
        secondaryButton: secondaryButton
      )
    }
  }

  @available(iOS 13, macOS 10.15, macCatalyst 13, tvOS 13, watchOS 6, *)
  extension AlertState.Button {
    @available(*, deprecated, message: "'label' should be 'TextState'")
    @_disfavoredOverload
    public static func cancel(
      _ label: LocalizedStringKey,
      send action: Action? = nil
    ) -> Self {
      Self(action: action.map(AlertState.ButtonAction.send), type: .cancel(label: .init(label)))
    }

    @available(*, deprecated, message: "'label' should be 'TextState'")
    @_disfavoredOverload
    public static func `default`(
      _ label: LocalizedStringKey,
      send action: Action? = nil
    ) -> Self {
      Self(action: action.map(AlertState.ButtonAction.send), type: .default(label: .init(label)))
    }

    @available(*, deprecated, message: "'label' should be 'TextState'")
    @_disfavoredOverload
    public static func destructive(
      _ label: LocalizedStringKey,
      send action: Action? = nil
    ) -> Self {
      Self(
        action: action.map(AlertState.ButtonAction.send), type: .destructive(label: .init(label)))
    }
  }
#endif

// NB: Deprecated after 0.9.0:

//extension Store {
//  @_disfavoredOverload
//  @available(*, deprecated, renamed: "producerScope(state:)")
//  public func scope<LocalState>(
//    state toLocalState: @escaping (Effect<State, Never>) -> Effect<LocalState, Never>
//  ) -> Effect<Store<LocalState, Action>, Never> {
//    self.producerScope(state: toLocalState)
//  }
//
//  @_disfavoredOverload
//  @available(*, deprecated, renamed: "producerScope(state:action:)")
//  public func scope<LocalState, LocalAction>(
//    state toLocalState: @escaping (Effect<State, Never>) -> Effect<LocalState, Never>,
//    action fromLocalAction: @escaping (LocalAction) -> Action
//  ) -> Effect<Store<LocalState, LocalAction>, Never> {
//    self.producerScope(state: toLocalState, action: fromLocalAction)
//  }
//}
//
//// NB: Deprecated after 0.6.0:
//
//extension Reducer {
//  @available(*, deprecated, renamed: "optional()")
//  public var optional: Reducer<State?, Action, Environment> {
//    self.optional()
//  }
//}