#if canImport(Combine)
import Combine

public extension SignalProducer {
  
  func asPublisher() -> Combine.AnyPublisher<Value, Error> {
    ReactiveSwiftPublisher(upstream: self)
      .eraseToAnyPublisher()
  }
}

public class ReactiveSwiftPublisher<Upstream: SignalProducerConvertible>: Publisher {
  
  public typealias Output = Upstream.Value
  public typealias Failure = Upstream.Error
  
  private let upstream: Upstream
  
  init(upstream: Upstream) {
    self.upstream = upstream
  }
  
  public func receive<S>(subscriber: S) where S : Subscriber, Upstream.Error == S.Failure, Upstream.Value == S.Input {
    subscriber.receive(subscription: ReactiveSwiftSubscription(upstream: upstream, downstream: subscriber))
  }
  
}
#endif
