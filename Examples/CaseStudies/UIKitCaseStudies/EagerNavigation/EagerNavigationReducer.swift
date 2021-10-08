import ComposableArchitecture
import Foundation

let EagerNavigationReducer = Reducer<EagerNavigationState, EagerNavigationAction, EagerNavigationEnvironment>.combine(
  CounterReducer
    .optional()
    .pullback(state: \.optionalCounter, action: /EagerNavigationAction.optionalCounter, environment: { _ in
    .init()
    }),
  Reducer { state, action, environment in
    struct CancelId: Hashable {}
    switch action {
    case .viewDidLoad:
      break
    case .viewWillAppear:
      break
    case .viewWillDisappear:
      break
    case .setNavigation(isActive: true):
      state.isNavigationActive = true
      return Effect(value: .setNavigationIsActiveDelayCompleted)
        .delay(1, on: QueueScheduler.main)
    case .setNavigation(isActive: false):
      state.isNavigationActive = false
      state.optionalCounter = nil
      return .none
    case .setNavigationIsActiveDelayCompleted:
      state.optionalCounter = CounterState()
      return .none
    case .optionalCounter:
      return .none
    default:
      break
    }
    return .none
  }
)
  .debug()