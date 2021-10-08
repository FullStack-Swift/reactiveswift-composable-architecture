#if canImport(Combine)
import Combine
import ReactiveSwift

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
  func eraseToEffect() -> Effect<Output, Failure> {
    SignalProducer<Output, Failure> { observer, disposable in
      let cancellable = self.sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            observer.sendCompleted()
          case .failure(let error):
            observer.send(error: error)
          }
        },
        receiveValue: { value in
          observer.send(value: value)
        })
      
      disposable.observeEnded {
        cancellable.cancel()
      }
    }
  }
}
#endif
