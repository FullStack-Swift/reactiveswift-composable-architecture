extension Effect {
  /// Creates an effect from a Combine publisher.
  ///
  /// - Parameter createPublisher: The closure to execute when the effect is performed.
  /// - Returns: An effect wrapping a Combine publisher.
  public static func publisher<P: SignalProducerConvertible>(_ createPublisher: @escaping () -> P) -> Self
  where P.Value == Action, P.Error == Never {
    Self(
      operation: .publisher(
        withEscapedDependencies { continuation in
          continuation.yield {
            createPublisher()
              .producer
          }
        }
      )
    )
  }
}


public struct _EffectPublisher<Action>: SignalProducerProtocol, SignalProducerConvertible {
  public typealias Value = Action
  public typealias Error = Never
  
  let effect: Effect<Action>
  
  public init(_ effect: Effect<Action>) {
    self.effect = effect
  }
  
  public var producer: ReactiveSwift.SignalProducer<Action, Never> {
    publisher
  }
  
  private var publisher: EffectAction<Action> {
    switch self.effect.operation {
      case .none:
        return EffectAction.empty
      case let .publisher(publisher):
        return publisher
      case let .run(priority, operation):
        return EffectAction { (observer, disposable) in
          let task = Task(priority: priority) { @MainActor in
            defer { observer.sendCompleted() }
            await operation(Send { observer.send(value: $0) })
          }
          disposable.observeEnded {
            task.cancel()
          }
        }
    }
  }
}

