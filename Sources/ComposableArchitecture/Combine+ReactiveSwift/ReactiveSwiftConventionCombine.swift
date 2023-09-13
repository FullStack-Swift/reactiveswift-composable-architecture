import ReactiveSwift
import Foundation

public typealias EffectAction<Action> = SignalProducer<Action, Never>

typealias AnyPublisher<Output, Failure: Error> = SignalProducer<Output, Failure>

public enum ReactiveSwiftCombine {
  
  /// A signal that a publisher doesn’t produce additional elements, either due to normal completion or an error.
  public enum Completion<Failure> where Failure: Error {
    
    /// The publisher finished normally.
    case finished
    
    /// The publisher stopped publishing due to the indicated error.
    case failure(Failure)
    
    public init(failure: Failure) {
      self = .failure(failure)
    }
  }
}

extension SignalProducer {
  
  func send(_ element: Value) {
    
  }
  
  func send(completion: ReactiveSwiftCombine.Completion<Error>) {
    
  }
  
  /// Republishes elements until another publisher emits an element.
  ///
  /// After the second publisher publishes an element, the publisher returned by this method finishes.
  ///
  /// - Parameter publisher: A second publisher.
  /// - Returns: A publisher that republishes elements until the second publisher publishes an element.
  func prefix(untilOutputFrom: some SignalProducerConvertible) -> Self {
    self.asPublisher()
      .prefix(untilOutputFrom: untilOutputFrom.producer.asPublisher())
      .asSignalProducer()
  }
  
  /// Omits the specified number of elements before republishing subsequent elements.
  ///
  /// Use ``Publisher/dropFirst(_:)`` when you want to drop the first `n` elements from the upstream publisher, and republish the remaining elements.
  ///
  /// The example below drops the first five elements from the stream:
  ///
  ///     let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  ///     cancellable = numbers.publisher
  ///         .dropFirst(5)
  ///         .sink { print("\($0)", terminator: " ") }
  ///
  ///     // Prints: "6 7 8 9 10 "
  ///
  /// - Parameter count: The number of elements to omit. The default is `1`.
  /// - Returns: A publisher that doesn’t republish the first `count` elements.
  func dropFirst(_ count: Int = 1) -> Self {
    skip(first: count)
  }
  
  /// Performs the specified closures when publisher events occur.
  ///
  /// Use ``Publisher/handleEvents(receiveSubscription:receiveOutput:receiveCompletion:receiveCancel:receiveRequest:)`` when you want to examine elements as they progress through the stages of the publisher’s lifecycle.
  ///
  /// In the example below, a publisher of integers shows the effect of printing debugging information at each stage of the element-processing lifecycle:
  ///
  ///     let integers = (0...2)
  ///     cancellable = integers.publisher
  ///         .handleEvents(receiveSubscription: { subs in
  ///             print("Subscription: \(subs.combineIdentifier)")
  ///         }, receiveOutput: { anInt in
  ///             print("in output handler, received \(anInt)")
  ///         }, receiveCompletion: { _ in
  ///             print("in completion handler")
  ///         }, receiveCancel: {
  ///             print("received cancel")
  ///         }, receiveRequest: { (demand) in
  ///             print("received demand: \(demand.description)")
  ///         })
  ///         .sink { _ in return }
  ///
  ///     // Prints:
  ///     //   received demand: unlimited
  ///     //   Subscription: 0x7f81284734c0
  ///     //   in output handler, received 0
  ///     //   in output handler, received 1
  ///     //   in output handler, received 2
  ///     //   in completion handler
  ///
  ///
  /// - Parameters:
  ///   - receiveSubscription: An optional closure that executes when the publisher receives the subscription from the upstream publisher. This value defaults to `nil`.
  ///   - receiveOutput: An optional closure that executes when the publisher receives a value from the upstream publisher. This value defaults to `nil`.
  ///   - receiveCompletion: An optional closure that executes when the upstream publisher finishes normally or terminates with an error. This value defaults to `nil`.
  ///   - receiveCancel: An optional closure that executes when the downstream receiver cancels publishing. This value defaults to `nil`.
  ///   - receiveRequest: An optional closure that executes when the publisher receives a request for more elements. This value defaults to `nil`.
  /// - Returns: A publisher that performs the specified closures when publisher events occur.
  func handleEvents(
    receiveSubscription: ((()) -> Void)? = nil,
    receiveOutput: ((Value) -> Void)? = nil,
    receiveCompletion: ((ReactiveSwiftCombine.Completion<Error>) -> Void)? = nil,
    receiveCancel: (() -> Void)? = nil,
    receiveRequest: ((()) -> Void)? = nil
  ) -> Self {
    return self.asPublisher()
      .handleEvents { _ in
        receiveSubscription?(())
      } receiveOutput: { ouput in
        receiveOutput?(ouput)
      } receiveCompletion: { completion in
        switch completion {
          case .failure(let error):
            receiveCompletion?(.failure(error))
          case .finished:
            receiveCompletion?(.finished)
        }
      } receiveCancel: {
        receiveCancel?()
      } receiveRequest: { _ in
        receiveRequest?(())
      }
      .asSignalProducer()
  }
  
  public func sink(
    receiveCompletion: @escaping ((ReactiveSwiftCombine.Completion<Error>) -> Void),
    receiveValue: @escaping ((Self.Value) -> Void))
  -> Disposable {
    start(
      .init(
        value: receiveValue,
        failed: { error in
          receiveCompletion(.failure(error))
        },
        completed: {
          receiveCompletion(.finished)
        },
        interrupted: {
          receiveCompletion(.finished)
        }
      )
    )
  }
  
  public func sink(
    receiveValue: @escaping ((Value) -> Void)
  ) -> Disposable {
    start(.init(value: receiveValue))
  }
  
  public func eraseToAnyPublisher() -> SignalProducer<Value, Error> {
    producer
  }
  
  public func removeDuplicates(
    by predicate: @escaping (Value, Value) -> Bool
  ) -> Self {
    skipRepeats(predicate)
  }
}

extension SignalProducer where Value: Equatable {
  public func removeDuplicates() -> Self {
    skipRepeats()
  }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, macCatalyst 13, *)
extension SignalProducer {
  public var values: AsyncThrowingStream<Value, Swift.Error> {
    AsyncThrowingStream<Value, Swift.Error> { continuation in
      let disposable = start { event in
        switch event {
          case .value(let value):
            continuation.yield(value)
          case .completed, .interrupted:
            continuation.finish()
          case .failed(let error):
            continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { @Sendable _ in
        disposable.dispose()
      }
    }
  }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, macCatalyst 13, *)
extension SignalProducerConvertible where Error == Never {
  public var values: AsyncStream<Value> {
    AsyncStream<Value> { continuation in
      let disposable = producer.start { event in
        switch event {
          case .value(let value):
            continuation.yield(value)
          case .completed,
              .interrupted:
            continuation.finish()
          case .failed:
            fatalError("failed")
        }
      }
      continuation.onTermination = { @Sendable _ in
        disposable.dispose()
      }
    }
  }
}

extension StorePublisher {
  public func sink(
    receiveCompletion: @escaping ((ReactiveSwiftCombine.Completion<Never>) -> Void),
    receiveValue: @escaping ((Self.Value) -> Void))
  -> Disposable {
    producer.sink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
  }
  
  public func sink(
    receiveValue: @escaping ((Value) -> Void)
  ) -> Disposable {
    producer.sink(receiveValue: receiveValue)
  }
}

extension _EffectPublisher {
  public func sink(
    receiveCompletion: @escaping ((ReactiveSwiftCombine.Completion<Never>) -> Void),
    receiveValue: @escaping ((Self.Value) -> Void))
  -> Disposable {
    producer.sink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
  }
  
  public func sink(
    receiveValue: @escaping ((Value) -> Void)
  ) -> Disposable {
    producer.sink(receiveValue: receiveValue)
  }
}


public struct Deferred<DeferredPublisher>: SignalProducerConvertible
where DeferredPublisher : SignalProducerConvertible {
  
  public var producer: SignalProducer<Value, Error> {
    SignalProducer<Void, Error>(value: ())
      .flatMap(.merge, { _ in
        createProducer
      })
  }
  
  public typealias Value = DeferredPublisher.Value
  
  public typealias Error = DeferredPublisher.Error
  
  let createProducer: DeferredPublisher
  
  public init(_ createProducer: @escaping () -> DeferredPublisher) {
    self.createProducer = createProducer()
  }
  
}

public struct Empty<Output, Failure>: SignalProducerConvertible where Failure : Error {
  
  public var producer: ReactiveSwift.SignalProducer<Output, Failure> {
    core.output.producer
  }
  
  public typealias Value = Output
  
  public typealias Error = Failure
  
  private let core = Signal<Output, Failure>.pipe()
  
  public init(completeImmediately: Bool = true) {
    if completeImmediately {
      core.input.sendCompleted()
    }
  }
  
  public init(
    completeImmediately: Bool = true,
    outputType: Output.Type,
    failureType: Failure.Type
  ) {
    if completeImmediately {
      core.input.sendCompleted()
    }
  }
  
  public func eraseToAnyPublisher() -> ReactiveSwift.SignalProducer<Value, Error> {
    producer
  }
}

public struct Just<Output>: SignalProducerConvertible {
  
  public var producer: ReactiveSwift.SignalProducer<Value, Error> {
    core.output.producer
  }
  
  public typealias Value = Output
  
  public typealias Error = Never
  
  public typealias Failure = Never
  
  private let core = Signal<Value, Error>.pipe()
  
  //  Initializes a publisher that emits the specified output just once.
  public init(_ output: Output) {
    core.input.send(value: output)
    core.input.sendCompleted()
  }
  
  public func eraseToAnyPublisher() -> ReactiveSwift.SignalProducer<Value, Error> {
    producer
  }
}

public final class PassthroughSubject<Output, Failure>: SignalProducerConvertible where Failure : Error {
  
  public typealias Value = Output
  
  public typealias Error = Failure
  
  public var producer: SignalProducer<Output, Failure> {
    core.output.producer
  }
  
  private let core = Signal<Output, Failure>.pipe()
  
  /// Creating a Passthrough Subjectin page link
  public init() {
    
  }
  
  public func eraseToAnyPublisher() -> ReactiveSwift.SignalProducer<Value, Error> {
    producer
  }
  
  /// Sends a value to the subscriber.
  /// - Parameter input: The value to send.
  final public func send(_ input: Output) {
    core.input.send(value: input)
  }
  
  /// Sends a completion signal to the subscriber.
  ///
  /// - Parameter completion: A `Completion` instance which indicates whether publishing has finished normally or failed with an error.
  final public func send(completion: ReactiveSwiftCombine.Completion<Failure>) {
    switch completion {
      case .finished:
        core.input.sendCompleted()
      case .failure(let failure):
        core.input.send(error: failure)
    }
  }
}

extension PassthroughSubject where Output == Void {
  final public func send() {
    core.input.send(value: ())
  }
}

extension SignalProducer {
  /// Delay `value` and `completed` events by the given interval, forwarding
  /// them on the given scheduler.
  ///
  /// - note: `failed` and `interrupted` events are always scheduled
  ///         immediately.
  ///
  /// - parameters:
  ///   - interval: Interval to delay `value` and `completed` events by.
  ///   - scheduler: A scheduler to deliver delayed events on.
  ///
  /// - returns: A producer that, when started, will delay `value` and
  ///            `completed` events and will yield them on given scheduler.
  public func delay(for interval: TimeInterval, scheduler: DateScheduler) -> SignalProducer<Value, Error> {
   delay(interval, on: scheduler)
  }
  
  public func receive(on: ReactiveSwift.Scheduler) -> SignalProducer<Value, Error> {
    observe(on: on)
  }
  
  public func subscribe(on: ReactiveSwift.Scheduler) -> SignalProducer<Value, Error> {
    observe(on: on)
  }
}

extension ReactiveSwift.DateScheduler {
  public var now: Date {
    currentDate
  }
}
