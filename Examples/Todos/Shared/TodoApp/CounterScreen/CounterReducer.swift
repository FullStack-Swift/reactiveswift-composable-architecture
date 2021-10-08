import ComposableArchitecture
import Foundation

let CounterReducer = Reducer<CounterState, CounterAction, CounterEnvironment>.combine(
  Reducer { state, action, environment in
    switch action {
    case .viewOnAppear:
      break
    case .viewOnDisappear:
      break
    case .decrement:
      state.count -= 1
    case .increment:
      state.count += 1
    default:
      break
    }
    return .none
  }
)
  .debug()
