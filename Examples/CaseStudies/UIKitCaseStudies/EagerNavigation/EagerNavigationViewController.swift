import ComposableArchitecture
import SwiftUI
import UIKit


final class EagerNavigationViewController: UIViewController {
  
  private let store: Store<EagerNavigationState, EagerNavigationAction>
  
  private let viewStore: ViewStore<ViewState, ViewAction>
  
  init(store: Store<EagerNavigationState, EagerNavigationAction>? = nil) {
    let unwrapStore = store ?? Store(initialState: EagerNavigationState(), reducer: EagerNavigationReducer, environment: EagerNavigationEnvironment())
    self.store = unwrapStore
    self.viewStore = ViewStore(unwrapStore.scope(state: ViewState.init, action: EagerNavigationAction.init))
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    viewStore.send(.viewDidLoad)
    title = "Navigate and load"
    view.backgroundColor = .systemBackground
    let button = UIButton(type: .system)
    button.setTitle("Load optional counter", for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(button)
    NSLayoutConstraint.activate([
      button.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
      button.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
    ])
    viewStore.action <~ button.reactive.controlEvents(.touchUpInside).map {_ in ViewAction.setNavigation(isActive: true)}
    viewStore.publisher.isNavigationActive.startWithValues { [weak self] isNavigationActive in
      guard let self = self else { return }
      if isNavigationActive {
        self.navigationController?.pushViewController(
          IfLetStoreController(
            store: self.store
              .scope(state: \.optionalCounter, action: EagerNavigationAction.optionalCounter),
            then: CounterViewController.init(store:),
            else: ActivityIndicatorViewController.init
          ),
          animated: true
        )
      } else {
        self.navigationController?.popToViewController(self, animated: true)
      }
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if !self.isMovingToParent {
      self.viewStore.send(.setNavigation(isActive: false))
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewStore.send(.viewWillAppear)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    viewStore.send(.viewWillDisappear)
  }
}

struct EagerNavigationViewController_Previews: PreviewProvider {
  static var previews: some View {
    let vc = EagerNavigationViewController()
    UIViewRepresented(makeUIView: { _ in vc.view })
  }
}

fileprivate struct ViewState: Equatable {
  var isNavigationActive = false
  var optionalCounter: CounterState?
  init(state: EagerNavigationState) {
    self.isNavigationActive = state.isNavigationActive
    self.optionalCounter = state.optionalCounter
  }
}

fileprivate enum ViewAction: Equatable {
  case viewDidLoad
  case viewWillAppear
  case viewWillDisappear
  case none
  case optionalCounter(CounterAction)
  case setNavigation(isActive: Bool)
  case setNavigationIsActiveDelayCompleted
  
  init(action: EagerNavigationAction) {
    switch action {
    case .viewDidLoad:
      self = .viewDidLoad
    case .viewWillAppear:
      self = .viewWillAppear
    case .viewWillDisappear:
      self = .viewWillDisappear
    default:
      self = .none
    }
  }
}

fileprivate extension EagerNavigationState {
  
  var viewState: ViewState {
    get {
      ViewState(state: self)
    }
    set {
      
    }
  }
}

fileprivate extension EagerNavigationAction {
  
  init(action: ViewAction) {
    switch action {
    case .viewDidLoad:
      self = .viewDidLoad
    case .viewWillAppear:
      self = .viewWillAppear
    case .viewWillDisappear:
      self = .viewWillDisappear
    case .optionalCounter(let counterAction):
      self = .optionalCounter(counterAction)
    case .setNavigation(let isActive):
      self = .setNavigation(isActive: isActive)
    case .setNavigationIsActiveDelayCompleted:
      self = .setNavigationIsActiveDelayCompleted
    default:
      self = .none
    }
  }
}
