import Foundation
import ReactiveSwift

extension Effect where Value == Date, Error == Never {
  public static func timer(
    id: AnyHashable,
    every interval: DispatchTimeInterval,
    tolerance: DispatchTimeInterval? = nil,
    on scheduler: DateScheduler
  ) -> Effect<Value, Error> {
    return SignalProducer.timer(
      interval: interval, on: scheduler, leeway: tolerance ?? .seconds(.max)
    )
    .cancellable(id: id, cancelInFlight: true)
  }
}
