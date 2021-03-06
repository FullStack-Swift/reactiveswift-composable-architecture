import ComposableArchitecture
import XCTest

final class ViewStoreTests: XCTestCase {

  override func setUp() {
    super.setUp()
    equalityChecks = 0
    subEqualityChecks = 0
  }

  func testPublisherFirehose() {
    let store = Store(
      initialState: 0,
      reducer: Reducer<Int, Void, Void>.empty,
      environment: ()
    )

    let viewStore = ViewStore(store)

    var emissionCount = 0
    viewStore.publisher.producer
      .startWithValues { _ in
        emissionCount += 1
      }

    XCTAssertNoDifference(emissionCount, 1)
    viewStore.send(())
    XCTAssertNoDifference(emissionCount, 1)
    viewStore.send(())
    XCTAssertNoDifference(emissionCount, 1)
    viewStore.send(())
    XCTAssertNoDifference(emissionCount, 1)
  }

  func testEqualityChecks() {
    let store = Store(
      initialState: State(),
      reducer: Reducer<State, Void, Void>.empty,
      environment: ()
    )

    let store1 = store.scope(state: { $0 })
    let store2 = store1.scope(state: { $0 })
    let store3 = store2.scope(state: { $0 })
    let store4 = store3.scope(state: { $0 })

    let viewStore1 = ViewStore(store1)
    let viewStore2 = ViewStore(store2)
    let viewStore3 = ViewStore(store3)
    let viewStore4 = ViewStore(store4)

    viewStore1.publisher.producer.startWithValues{ _ in }
    viewStore2.publisher.producer.startWithValues{ _ in }
    viewStore3.publisher.producer.startWithValues{ _ in }
    viewStore4.publisher.producer.startWithValues{ _ in }
    viewStore1.publisher.substate.producer.startWithValues{ _ in }
    viewStore2.publisher.substate.producer.startWithValues{ _ in }
    viewStore3.publisher.substate.producer.startWithValues{ _ in }
    viewStore4.publisher.substate.producer.startWithValues{ _ in }

    XCTAssertNoDifference(0, equalityChecks)
    XCTAssertNoDifference(0, subEqualityChecks)
    viewStore4.send(())
    XCTAssertNoDifference(4, equalityChecks)
    XCTAssertNoDifference(4, subEqualityChecks)
    viewStore4.send(())
    XCTAssertNoDifference(8, equalityChecks)
    XCTAssertNoDifference(8, subEqualityChecks)
    viewStore4.send(())
    XCTAssertNoDifference(12, equalityChecks)
    XCTAssertNoDifference(12, subEqualityChecks)
    viewStore4.send(())
    XCTAssertNoDifference(16, equalityChecks)
    XCTAssertNoDifference(16, subEqualityChecks)
  }

  func testAccessViewStoreStateInPublisherSink() {
    let reducer = Reducer<Int, Void, Void> { count, _, _ in
      count += 1
      return .none
    }

    let store = Store(initialState: 0, reducer: reducer, environment: ())
    let viewStore = ViewStore(store)

    var results: [Int] = []

    viewStore.publisher.producer
      .startWithValues({ _ in
        results.append(viewStore.state)
      })
    viewStore.send(())
    viewStore.send(())
    viewStore.send(())

    XCTAssertNoDifference([0, 1, 2, 3], results)
  }

  func testWillSet() {
    let reducer = Reducer<Int, Void, Void> { count, _, _ in
      count += 1
      return .none
    }

    let store = Store(initialState: 0, reducer: reducer, environment: ())
    let viewStore = ViewStore(store)

    var results: [Int] = []

    viewStore.objectWillChange.eraseToEffect()
      .startWithValues({ _ in
        results.append(viewStore.state)
      })
    
    viewStore.send(())
    viewStore.send(())
    viewStore.send(())

    XCTAssertNoDifference([0, 1, 2], results)
  }

  // MARK: TODO
  func disabled_testPublisherOwnsViewStore() {
    let reducer = Reducer<Int, Void, Void> { count, _, _ in
      count += 1
      return .none
    }
    let store = Store(initialState: 0, reducer: reducer, environment: ())

    var results: [Int] = []
    ViewStore(store)
      .publisher.producer
      .startWithValues { results.append($0) }
    ViewStore(store).send(())
    print(results)
    XCTAssertNoDifference(results, [0, 1])
  }

  func testStorePublisherSubscriptionOrder() {
    let reducer = Reducer<Int, Void, Void> { count, _, _ in
      count += 1
      return .none
    }
    let store = Store(initialState: 0, reducer: reducer, environment: ())
    let viewStore = ViewStore(store)

    var results: [Int] = []

    viewStore.publisher.producer
      .startWithValues { _ in results.append(0)}

    viewStore.publisher.producer
      .startWithValues { _ in results.append(1)}

    viewStore.publisher.producer
      .startWithValues { _ in results.append(2)}

    XCTAssertNoDifference(results, [0, 1, 2])

    for _ in 0..<9 {
      viewStore.send(())
    }

    XCTAssertNoDifference(results, Array(repeating: [0, 1, 2], count: 10).flatMap { $0 })
  }

  #if canImport(_Concurrency) && compiler(>=5.5.2)
    func testSendWhile() {
      let expectation = self.expectation(description: "await")
      Task { @MainActor in
        enum Action {
          case response
          case tapped
        }
        let reducer = Reducer<Bool, Action, Void> { state, action, environment in
          switch action {
          case .response:
            state = false
            return .none
          case .tapped:
            state = true
            return Effect(value: .response)
              .observe(on: QueueScheduler.main)
              .eraseToEffect()
          }
        }

        let store = Store(initialState: false, reducer: reducer, environment: ())
        let viewStore = ViewStore(store)

        XCTAssertNoDifference(viewStore.state, false)
        await viewStore.send(.tapped, while: { $0 })
        XCTAssertNoDifference(viewStore.state, false)
        expectation.fulfill()
      }
      self.wait(for: [expectation], timeout: 1)
    }

    func testSuspend() {
      let expectation = self.expectation(description: "await")
      Task { @MainActor in
        enum Action {
          case response
          case tapped
        }
        let reducer = Reducer<Bool, Action, Void> { state, action, environment in
          switch action {
          case .response:
            state = false
            return .none
          case .tapped:
            state = true
            return Effect(value: .response)
              .observe(on: QueueScheduler.main)
              .eraseToEffect()
          }
        }

        let store = Store(initialState: false, reducer: reducer, environment: ())
        let viewStore = ViewStore(store)

        XCTAssertNoDifference(viewStore.state, false)
        viewStore.send(.tapped)
        XCTAssertNoDifference(viewStore.state, true)
        await viewStore.suspend(while: { $0 })
        XCTAssertNoDifference(viewStore.state, false)
        expectation.fulfill()
      }
      self.wait(for: [expectation], timeout: 1)
    }
  #endif
}

private struct State: Equatable {
  var substate = Substate()

  static func == (lhs: Self, rhs: Self) -> Bool {
    equalityChecks += 1
    return lhs.substate == rhs.substate
  }
}

private struct Substate: Equatable {
  var name = "Blob"

  static func == (lhs: Self, rhs: Self) -> Bool {
    subEqualityChecks += 1
    return lhs.name == rhs.name
  }
}

private var equalityChecks = 0
private var subEqualityChecks = 0
