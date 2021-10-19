import ComposableArchitecture
import Foundation

let CounterReducer = Reducer<CounterState, CounterAction, CounterEnvironment>.combine(
  
  Reducer { state, action, environment in
    switch action {
    case .viewDidLoad:
      break
    case .viewWillAppear:
      break
    case .viewWillDisappear:
      break
    case .decrementButtonTapped:
      state.count -= 1
    case .incrementButtonTapped:
      state.count += 1
    default:
      break
    }
    return .none
  }
)
  .debug()
