import ComposableArchitecture
import Foundation

enum EagerNavigationAction: Equatable {
  case optionalCounter(CounterAction)
  case viewDidLoad
  case viewWillAppear
  case viewWillDisappear
  case none
  case setNavigation(isActive: Bool)
  case setNavigationIsActiveDelayCompleted
}
