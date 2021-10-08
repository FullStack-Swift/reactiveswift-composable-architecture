import Dispatch
import Foundation
import ReactiveSwift

extension Effect {
  public func throttle(
    id: AnyHashable,
    for interval: TimeInterval,
    scheduler: DateScheduler,
    latest: Bool
  ) -> Effect<Value, Error> {
    self.observe(on: scheduler)
      .flatMap(.latest) { value -> Effect<Value, Error> in
        throttleLock.lock()
        defer { throttleLock.unlock() }

        guard let throttleTime = throttleTimes[id] as! Date? else {
          throttleTimes[id] = scheduler.currentDate
          throttleValues[id] = nil
          return Effect(value: value)
        }

        let value = latest ? value : (throttleValues[id] as! Value? ?? value)
        throttleValues[id] = value

        guard
          scheduler.currentDate.timeIntervalSince1970 - throttleTime.timeIntervalSince1970
            < interval
        else {
          throttleTimes[id] = scheduler.currentDate
          throttleValues[id] = nil
          return Effect(value: value)
        }

        return Effect(value: value)
          .delay(
            throttleTime.addingTimeInterval(interval).timeIntervalSince1970
              - scheduler.currentDate.timeIntervalSince1970,
            on: scheduler
          ).on(
            value: { _ in
              throttleLock.sync {
                throttleTimes[id] = scheduler.currentDate
                throttleValues[id] = nil
              }
            }
          )
      }
      .cancellable(id: id, cancelInFlight: true)
  }
}

var throttleTimes: [AnyHashable: Any] = [:]
var throttleValues: [AnyHashable: Any] = [:]
let throttleLock = NSRecursiveLock()
