import Foundation
import ReactiveSwift

public typealias Effect<Value, Error: Swift.Error> = SignalProducer<Value, Error>

extension Effect {
  public static var none: Effect {
    .empty
  }
  
  public static func fireAndForget(_ work: @escaping () -> Void) -> Effect {
    .deferred { () -> SignalProducer<Value, Error> in
      work()
      return .empty
    }
  }
  
  public static func concatenate(_ effects: Effect...) -> Effect {
    .concatenate(effects)
  }
  
  public static func concatenate<C: Collection>(
    _ effects: C
  ) -> Effect where C.Element == Effect {
    guard let first = effects.first else { return .none }
    return effects
      .dropFirst()
      .reduce(into: first) { effects, effect in
        effects = effects.concat(effect)
      }
  }
  
  public static func deferred(_ createProducer: @escaping () -> SignalProducer<Value, Error>)
  -> SignalProducer<Value, Error>
  {
    Effect<Void, Error>(value: ())
      .flatMap(.merge, createProducer)
  }
  
  public static func future(
    _ attemptToFulfill: @escaping (@escaping (Result<Value, Error>) -> Void) -> Void
  ) -> Effect {
    SignalProducer { observer, _ in
      attemptToFulfill { result in
        switch result {
        case let .success(value):
          observer.send(value: value)
          observer.sendCompleted()
        case let .failure(error):
          observer.send(error: error)
        }
      }
    }
  }
  
  public func catchToEffect() -> Effect<Result<Value, Error>, Never> {
    self.map(Result<Value, Error>.success)
      .flatMapError { Effect<Result<Value, Error>, Never>(value: Result.failure($0)) }
  }
  
  public func catchToEffect<T>(
    _ transform: @escaping (Result<Value, Error>) -> T
  ) -> Effect<T, Never> {
    self
      .map { transform(.success($0)) }
      .flatMapError { Effect<T, Never>(value: transform(.failure($0))) }
  }
  
  public func fireAndForget<NewValue, NewError>(
    outputType: NewValue.Type = NewValue.self,
    failureType: NewError.Type = NewError.self
  ) -> Effect<NewValue, NewError> {
    self.flatMapError { _ in .empty }
    .flatMap(.latest) { _ in
    .empty
    }
  }
  
  public func eraseToEffect() -> Self {
    self
  }
}

extension Effect where Self.Error == Never {
  @discardableResult
  public func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Value>, on object: Root)
  -> Disposable
  {
    self.startWithValues { value in
      object[keyPath: keyPath] = value
    }
  }
}
