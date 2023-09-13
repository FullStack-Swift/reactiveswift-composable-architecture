#if canImport(Combine)
import Combine

class ReactiveSwiftSubscription<Upstream: SignalProducerConvertible, Downstream: Combine.Subscriber>: Combine.Subscription
where Downstream.Input == Upstream.Value, Downstream.Failure == Upstream.Error {
  private var disposable: Disposable?
  private let buffer: DemandBuffer<Downstream>
  
  init(upstream: Upstream, downstream: Downstream) {
    buffer = DemandBuffer(subscriber: downstream)
    disposable = upstream.producer.start(.init(bufferEvents))
  }
  
  private func bufferEvents(_ event: Signal<Upstream.Value, Upstream.Error>.Event) {
    switch event {
      case .value(let value):
        _ = self.buffer.buffer(value: value)
      case .failed(let error):
        self.buffer.complete(completion: .failure(error))
      case .completed:
        self.buffer.complete(completion: .finished)
      case .interrupted:
        self.buffer.complete(completion: .finished)
    }
  }
  
  func request(_ demand: Subscribers.Demand) {
    _ = self.buffer.demand(demand)
  }
  
  func cancel() {
    disposable?.cancel()
    disposable = nil
  }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension ReactiveSwiftSubscription: CustomStringConvertible {
  var description: String {
    return "ReactiveSwiftSubscription<\(Upstream.self)>"
  }
}

// MARK: - Infallible
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class ReactiveSwiftInfallibleSubscription<Upstream: SignalProducerConvertible, Downstream: Combine.Subscriber>: Combine.Subscription
where Downstream.Input == Upstream.Value, Downstream.Failure == Never, Upstream.Error == Never {
  private var disposable: Disposable?
  private let buffer: DemandBuffer<Downstream>
  
  init(upstream: Upstream, downstream: Downstream) {
    buffer = DemandBuffer(subscriber: downstream)
    disposable = upstream.producer.start(.init(bufferEvents))
  }
  
  private func bufferEvents(_ event: Signal<Upstream.Value, Upstream.Error>.Event) {
    switch event {
      case .value(let value):
        _ = self.buffer.buffer(value: value)
      case .completed:
        self.buffer.complete(completion: .finished)
      case .interrupted:
        self.buffer.complete(completion: .finished)
    }
  }
  
  func request(_ demand: Subscribers.Demand) {
    _ = self.buffer.demand(demand)
  }
  
  func cancel() {
    disposable?.cancel()
    disposable = nil
  }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension ReactiveSwiftInfallibleSubscription: CustomStringConvertible {
  var description: String {
    return "ReactiveSwiftInfallibleSubscription<\(Upstream.self)>"
  }
}
#endif
