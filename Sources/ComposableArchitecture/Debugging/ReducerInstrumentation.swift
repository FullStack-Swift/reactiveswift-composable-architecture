#if canImport(os)
import os.signpost

extension Reducer {
  @available(iOS 12.0, *)
  public func signpost(
    _ prefix: String = "",
    log: OSLog = OSLog(
      subsystem: "co.pointfree.composable-architecture",
      category: "Reducer Instrumentation"
    )
  ) -> Self {
    guard log.signpostsEnabled else { return self }
    
    // NB: Prevent rendering as "N/A" in Instruments
    let zeroWidthSpace = "\u{200B}"
    
    let prefix = prefix.isEmpty ? zeroWidthSpace : "[\(prefix)] "
    
    return Self { state, action, environment in
      var actionOutput: String!
      if log.signpostsEnabled {
        actionOutput = debugCaseOutput(action)
        os_signpost(.begin, log: log, name: "Action", "%s%s", prefix, actionOutput)
      }
      let effects = self.run(&state, action, environment)
      if log.signpostsEnabled {
        os_signpost(.end, log: log, name: "Action")
        return effects
          .effectSignpost(prefix, log: log, actionOutput: actionOutput)
      }
      return effects
    }
  }
}

extension Effect where Error == Never {
  @available(iOS 12.0, *)
  func effectSignpost(
    _ prefix: String,
    log: OSLog,
    actionOutput: String
  ) -> Effect<Value, Error> {
    let sid = OSSignpostID(log: log)
    
    return self.on(
      starting: {
        os_signpost(
          .begin, log: log, name: "Effect", signpostID: sid, "%sStarted from %s", prefix,
          actionOutput
        )
      },
      completed: {
        os_signpost(.end, log: log, name: "Effect", signpostID: sid, "%sFinished", prefix)
      },
      disposed: {
        os_signpost(.end, log: log, name: "Effect", signpostID: sid, "%sCancelled", prefix)
      },
      value: { value in
        os_signpost(
          .event, log: log, name: "Effect Output", "%sOutput from %s", prefix, actionOutput
        )
      })
  }
}
#endif

func debugCaseOutput(_ value: Any) -> String {
  func debugCaseOutputHelp(_ value: Any) -> String {
    let mirror = Mirror(reflecting: value)
    switch mirror.displayStyle {
    case .enum:
      guard let child = mirror.children.first else {
        let childOutput = "\(value)"
        return childOutput == "\(type(of: value))" ? "" : ".\(childOutput)"
      }
      let childOutput = debugCaseOutputHelp(child.value)
      return ".\(child.label ?? "")\(childOutput.isEmpty ? "" : "(\(childOutput))")"
    case .tuple:
      return mirror.children.map { label, value in
        let childOutput = debugCaseOutputHelp(value)
        return "\(label.map { isUnlabeledArgument($0) ? "_:" : "\($0):" } ?? "")\(childOutput.isEmpty ? "" : " \(childOutput)")"
      }
      .joined(separator: ", ")
    default:
      return ""
    }
  }
  
  return "\(type(of: value))\(debugCaseOutputHelp(value))"
}

private func isUnlabeledArgument(_ label: String) -> Bool {
  label.firstIndex(where: { $0 != "." && !$0.isNumber }) == nil
}