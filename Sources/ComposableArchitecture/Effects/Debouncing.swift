import Foundation
import ReactiveSwift

extension Effect {
  public func debounce(
    id: AnyHashable,
    for dueTime: TimeInterval,
    scheduler: DateScheduler
  ) -> Effect<Value, Error> {
    Effect<Void, Never>.init(value: ())
      .promoteError(Error.self)
      .delay(dueTime, on: scheduler)
      .flatMap(.latest) { self.observe(on: scheduler) }
      .cancellable(id: id, cancelInFlight: true)
  }
}
