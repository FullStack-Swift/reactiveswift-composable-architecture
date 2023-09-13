import Foundation

public typealias AnyCancellable = AnyDisposable

extension AnyDisposable: Hashable {
  public static func == (lhs: AnyDisposable, rhs: AnyDisposable) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}


extension Disposable {
  func cancel() {
    dispose()
  }
}

extension Disposable {
  public func store(in set: inout Set<AnyDisposable>) {
    set.insert(AnyDisposable(self))
  }
}

#if(canImport(Combine))
import Combine

extension Cancellable {
  public func store(in set: inout Set<AnyDisposable>) {
    set.insert(AnyDisposable{ self.cancel() })
  }
}
#endif
