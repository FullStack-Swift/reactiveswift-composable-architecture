import Foundation
import ReactiveSwift

extension Effect {
  public func deferred(
    for dueTime: TimeInterval,
    scheduler: DateScheduler
  ) -> Effect<Value, Error> {
    SignalProducer<Void, Never>(value: ())
      .delay(dueTime, on: scheduler)
      .flatMap(.latest) { self.observe(on: scheduler) }
  }
}
