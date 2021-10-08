import ComposableArchitecture
import SwiftUI
import UIKit
import ReactiveCocoa

final class CounterViewController: UIViewController {
  
  private let store: Store<CounterState, CounterAction>
  
  private let viewStore: ViewStore<ViewState, ViewAction>
  
  init(store: Store<CounterState, CounterAction>? = nil) {
    let unwrapStore = store ?? Store(initialState: CounterState(), reducer: CounterReducer, environment: CounterEnvironment())
    self.store = unwrapStore
    self.viewStore = ViewStore(unwrapStore.scope(state: ViewState.init, action: CounterAction.init))
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    viewStore.send(.viewDidLoad)
    view.backgroundColor = .systemBackground
    let decrementButton = UIButton(type: .system)
    decrementButton.setTitle("−", for: .normal)
    let countLabel = UILabel()
    countLabel.font = .monospacedDigitSystemFont(ofSize: 17, weight: .regular)
    let incrementButton = UIButton(type: .system)
    incrementButton.setTitle("+", for: .normal)
    let rootStackView = UIStackView(arrangedSubviews: [
      decrementButton,
      countLabel,
      incrementButton,
    ])
    rootStackView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(rootStackView)
    NSLayoutConstraint.activate([
      rootStackView.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
      rootStackView.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
    ])
    //binding view to store
    viewStore.action <~ incrementButton.reactive.controlEvents(.touchUpInside).map {_ in ViewAction.incrementButtonTapped}
    viewStore.action <~ decrementButton.reactive.controlEvents(.touchUpInside).map {_ in ViewAction.decrementButtonTapped}
    //bind store to view
    countLabel.reactive.text <~ viewStore.publisher.count.map {String($0)}
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

struct CounterViewController_Previews: PreviewProvider {
  static var previews: some View {
    let vc = CounterViewController()
    UIViewRepresented(makeUIView: { _ in vc.view })
  }
}

fileprivate struct ViewState: Equatable {
  var count = 0
  init(state: CounterState) {
    count = state.count
  }
}

fileprivate enum ViewAction: Equatable {
  case viewDidLoad
  case viewWillAppear
  case viewWillDisappear
  case none
  case decrementButtonTapped
  case incrementButtonTapped
  
  init(action: CounterAction) {
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

fileprivate extension CounterState {
  
  var viewState: ViewState {
    get {
      ViewState(state: self)
    }
    set {
      
    }
  }
}

fileprivate extension CounterAction {
  
  init(action: ViewAction) {
    switch action {
    case .viewDidLoad:
      self = .viewDidLoad
    case .viewWillAppear:
      self = .viewWillAppear
    case .viewWillDisappear:
      self = .viewWillDisappear
    case .decrementButtonTapped:
      self = .decrementButtonTapped
    case .incrementButtonTapped:
      self = .incrementButtonTapped
    default:
      self = .none
    }
  }
}
