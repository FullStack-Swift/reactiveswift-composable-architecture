import ComposableArchitecture
import Foundation

enum MainAction: Equatable {
  case viewDidLoad
  case viewWillAppear
  case viewWillDisappear
  case none
  case logout
  case changRootScreen(RootScreen)
}
