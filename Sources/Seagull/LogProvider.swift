

public protocol LogProtocol {
    func info(_ msg: String, _ params: Any...)
    func warning(_ msg: String, _ params: Any...)
    func error(_ msg: String, _ params: Any...)
}

///////////////////////////////////////////////////////////////////////////////////////////

final class DefaultLogger: LogProtocol  {
    
    func info(_ msg: String, _ params: Any...) {
        printMsg(String(format: msg, params), prefix: Prefix.info)
    }
    
    func warning(_ msg: String, _ params: Any...) {
        printMsg(String(format: msg, params), prefix: Prefix.warning)
    }
    
    func error(_ msg: String, _ params: Any...) {
        printMsg(String(format: msg, params), prefix: Prefix.error)
    }
    
    // MARK: -
    
    private struct Prefix {
        static let info = "👌[INFO]"
        static let warning = "⚠️[WARNING]"
        static let error = "❗️[ERROR]"
    }
    
    func printMsg(_ msg: String, prefix: String) {
          print("\(prefix) \(msg)")
    }
}
