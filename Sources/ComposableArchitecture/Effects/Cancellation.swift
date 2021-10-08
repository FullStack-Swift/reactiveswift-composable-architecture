import Foundation
import ReactiveSwift

extension AnyDisposable: Hashable {
  public static func == (lhs: AnyDisposable, rhs: AnyDisposable) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}

extension Effect {
  public func cancellable(id: AnyHashable, cancelInFlight: Bool = false) -> Effect {
    let effect = Effect.deferred { () -> SignalProducer<Value, Error> in
      cancellablesLock.lock()
      defer { cancellablesLock.unlock() }
      
      let subject = Signal<Value, Error>.pipe()
      
      var values: [Value] = []
      var isCaching = true
      
      let disposable =
      self
        .on(value: {
          guard isCaching else { return }
          values.append($0)
        })
        .start(subject.input)
      
      var cancellationDisposable: AnyDisposable!
      cancellationDisposable = AnyDisposable {
        cancellablesLock.sync {
          subject.input.sendCompleted()
          disposable.dispose()
          cancellationCancellables[id]?.remove(cancellationDisposable)
          if cancellationCancellables[id]?.isEmpty == .some(true) {
            cancellationCancellables[id] = nil
          }
        }
      }
      
      cancellationCancellables[id, default: []].insert(
        cancellationDisposable
      )
      
      return SignalProducer(values)
        .concat(subject.output.producer)
        .on(
          started: { isCaching = false },
          completed: cancellationDisposable.dispose,
          interrupted: cancellationDisposable.dispose,
          terminated: cancellationDisposable.dispose,
          disposed: cancellationDisposable.dispose
        )
    }
    
    return cancelInFlight ? .concatenate(.cancel(id: id), effect) : effect
  }
  
  public static func cancel(id: AnyHashable) -> Effect {
    return .fireAndForget {
      cancellablesLock.sync {
        cancellationCancellables[id]?.forEach { $0.dispose() }
      }
    }
  }
  
  public static func cancel(ids: AnyHashable...) -> Effect {
    .cancel(ids: ids)
  }
  
  public static func cancel(ids: [AnyHashable]) -> Effect {
    .merge(ids.map(Effect.cancel(id:)))
  }
}

var cancellationCancellables: [AnyHashable: Set<AnyDisposable>] = [:]
let cancellablesLock = NSRecursiveLock()
