import Dispatch
import Foundation

extension Effect {
  /// Throttles an effect so that it only publishes one output per given interval.
  ///
  /// The throttling of an effect is with respect to actions being sent into the store. So, if
  /// you return a throttled effect from an action that is sent with high frequency, the effect
  /// will be executed at most once per interval specified.
  ///
  /// > Note: It is usually better to perform throttling logic in the _view_ in order to limit
  /// the number of actions sent into the system. Only use this operator if your reducer needs to
  /// layer on specialized logic for throttling. See <doc:Performance> for more information of why
  /// sending high-frequency actions into a store is typically not what you want to do.
  ///
  /// - Parameters:
  ///   - id: The effect's identifier.
  ///   - interval: The interval at which to find and emit the most recent element, expressed in
  ///     the time system of the scheduler.
  ///   - scheduler: The scheduler you want to deliver the throttled output to.
  ///   - latest: A boolean value that indicates whether to publish the most recent element. If
  ///     `false`, the publisher emits the first element received during the interval.
  /// - Returns: An effect that emits either the most-recent or first element received during the
  ///   specified interval.
  public func throttle<ID: Hashable, S: DateScheduler>(
    id: ID,
    for interval: TimeInterval,
    scheduler: S,
    latest: Bool
  ) -> Self {
    switch self.operation {
      case .none:
        return .none
      case .run:
        return .publisher { _EffectPublisher(self) }
          .throttle(id: id, for: interval, scheduler: scheduler, latest: latest)
        
      case let .publisher(publisher):
        return .publisher {
          publisher
            .receive(on: scheduler)
            .flatMap(.latest) { value -> AnyPublisher<Action, Never> in
              throttleLock.lock()
              defer { throttleLock.unlock() }
              
              guard let throttleTime = throttleTimes[id] as! Date? else {
                throttleTimes[id] = scheduler.now
                throttleValues[id] = nil
                return Just(value).eraseToAnyPublisher()
              }
              
              let value = latest ? value : (throttleValues[id] as! Action? ?? value)
              throttleValues[id] = value
              
              guard throttleTime.distance(to: scheduler.now) < interval else {
                throttleTimes[id] = scheduler.now
                throttleValues[id] = nil
                return Just(value).eraseToAnyPublisher()
              }
              
              return Just(value).eraseToAnyPublisher()
                .delay(
                  for: throttleTime.addingTimeInterval(interval).timeIntervalSince1970
                  - scheduler.currentDate.timeIntervalSince1970,
                  scheduler: scheduler
                )
                .handleEvents(
                  receiveOutput: { _ in
                    throttleLock.sync {
                      throttleTimes[id] = scheduler.now
                      throttleValues[id] = nil
                    }
                  }
                )
                .eraseToAnyPublisher()
            }
        }
        .cancellable(id: id, cancelInFlight: true)
    }
  }
}

var throttleTimes: [AnyHashable: Any] = [:]
var throttleValues: [AnyHashable: Any] = [:]
let throttleLock = NSRecursiveLock()
