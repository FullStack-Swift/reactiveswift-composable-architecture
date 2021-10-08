import ReactiveSwift

extension Store {
  @discardableResult
  public func ifLet<Wrapped>(
    then unwrap: @escaping (Store<Wrapped, Action>) -> Void,
    else: @escaping () -> Void = {}
  ) -> Disposable where State == Wrapped? {
    return self.state
      .skipRepeats({($0 != nil) == ($1 != nil)})
      .producer.startWithValues { state in
        if var state = state {
          unwrap(self.scope {
            state = $0 ?? state
            return state
          })
        } else {
          `else`()
        }
      }
  }
}
