import Foundation

extension Effect {
  /// Turns an effect into one that can be debounced.
  ///
  /// To turn an effect into a debounce-able one you must provide an identifier, which is used to
  /// determine which in-flight effect should be canceled in order to start a new effect. Any
  /// hashable value can be used for the identifier, such as a string, but you can add a bit of
  /// protection against typos by defining a new type that conforms to `Hashable`, such as an empty
  /// struct:
  ///
  /// ```swift
  /// case let .textChanged(text):
  ///   enum CancelID { case search }
  ///
  ///   return self.apiClient.search(text)
  ///     .debounce(id: CancelID.search, for: 0.5, scheduler: self.mainQueue)
  ///     .map(Action.searchResponse)
  /// ```
  ///
  /// - Parameters:
  ///   - id: The effect's identifier.
  ///   - dueTime: The duration you want to debounce for.
  ///   - scheduler: The scheduler you want to deliver the debounced output to.
  ///   - options: Scheduler options that customize the effect's delivery of elements.
  /// - Returns: An effect that publishes events only after a specified time elapses.
  public func debounce<ID: Hashable, S: DateScheduler>(
    id: ID,
    for dueTime: TimeInterval,
    scheduler: S
  ) -> Self {
    switch self.operation {
      case .none:
        return .none
      case .publisher, .run:
        return Self(
          operation: .publisher(
            Just(()).producer
              .delay(dueTime, on: scheduler)
              .flatMap(.latest) { _EffectPublisher(self).producer.observe(on: scheduler) }
              .producer
          )
        )
        .cancellable(id: id, cancelInFlight: true)
    }
  }
}
