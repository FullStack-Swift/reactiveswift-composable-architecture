import ReactiveSwift
import SwiftUI
import Combine

#if compiler(>=5.5) && canImport(_Concurrency)
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
extension Effect {
  public static func task(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async -> Value
  ) -> Self where Error == Never {
    var task: Task<Void, Never>?
    return .future { callback in
      task = Task(priority: priority) {
        guard !Task.isCancelled else { return }
        let output = await operation()
        guard !Task.isCancelled else { return }
        callback(.success(output))
      }
    }
    .on(disposed: { task?.cancel() })
  }
  
  public static func task(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async throws -> Value
  ) -> Self where Error == Swift.Error {
    deferred {
      var task: Task<(), Never>?
      let producer = SignalProducer { observer, lifetime in
        task = Task(priority: priority) {
          do {
            try Task.checkCancellation()
            let output = try await operation()
            try Task.checkCancellation()
            observer.send(value: output)
            observer.sendCompleted()
          } catch is CancellationError {
            observer.sendCompleted()
          } catch {
            observer.send(error: error)
          }
        }
      }
      
      return producer.on(disposed: task?.cancel)
    }
  }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
extension ViewStore {
  public func send(
    _ action: Action,
    while predicate: @escaping (State) -> Bool
  ) async {
    self.send(action)
    await self.suspend(while: predicate)
  }
  
#if canImport(SwiftUI)
  public func send(
    _ action: Action,
    animation: Animation?,
    while predicate: @escaping (State) -> Bool
  ) async {
    withAnimation(animation) { self.send(action) }
    await self.suspend(while: predicate)
  }
#endif
  public func suspend(while predicate: @escaping (State) -> Bool) async {
    let cancellable = Box<Disposable?>(wrappedValue: nil)
    try? await withTaskCancellationHandler(
      handler: { cancellable.wrappedValue?.dispose() },
      operation: {
        try Task.checkCancellation()
        try await withUnsafeThrowingContinuation {
          (continuation: UnsafeContinuation<Void, Error>) in
          guard !Task.isCancelled else {
            continuation.resume(throwing: CancellationError())
            return
          }
          cancellable.wrappedValue = self.publisher.producer
            .filter { !predicate($0) }
            .take(first: 1)
            .startWithValues { _ in
              continuation.resume()
              _ = cancellable
            }
        }
      }
    )
  }
}

private class Box<Value> {
  var wrappedValue: Value
  
  init(wrappedValue: Value) {
    self.wrappedValue = wrappedValue
  }
}
#endif
