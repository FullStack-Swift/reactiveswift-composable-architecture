extension SignalProducer {
  /// A ``SignalProducer`` that waits until it is started before running
  /// the supplied closure to create a new ``SignalProducer``, whose values
  /// are then sent to the subscriber of this effect.
  public static func deferred(_ createProducer: @escaping () -> Self) -> Self {
    SignalProducer<Void, Error>(value: ())
      .flatMap(.merge, createProducer)
  }

}
