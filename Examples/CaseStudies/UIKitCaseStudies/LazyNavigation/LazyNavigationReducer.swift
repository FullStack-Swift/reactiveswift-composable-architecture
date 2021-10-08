import ComposableArchitecture
import Foundation

let LazyNavigationReducer = Reducer<LazyNavigationState, LazyNavigationAction, LazyNavigationEnvironment>.combine(
  CounterReducer
    .optional()
    .pullback(state: \.optionalCounter,action: /LazyNavigationAction.optionalCounter,environment: { _ in
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
      state.isActivityIndicatorHidden = false
      return Effect(value: .setNavigationIsActiveDelayCompleted)
        .delay(1, on: QueueScheduler.main)
    case .setNavigation(isActive: false):
      state.optionalCounter = nil
      return .none
    case .setNavigationIsActiveDelayCompleted:
      state.isActivityIndicatorHidden = true
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
