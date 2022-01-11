import Combine
import ReactiveSwift

public extension Publisher {
    /// Convert the publisher to an Effect
    /// - Returns: Effect
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

//extension SignalProducer {
    ///  Convert the observable to an AnyPublisher
//  var publisher: AnyPublisher<Value, Error> {
//    fatalError()
//  }
//}
