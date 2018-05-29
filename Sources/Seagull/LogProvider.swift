import Foundation

public protocol LogProtocol {
    func info(_ msg: String, _ params: Any...)
    func warning(_ msg: String, _ params: Any...)
    func error(_ msg: String, _ params: Any...)
}

///////////////////////////////////////////////////////////////////////////////////////////

public final class DefaultLogger: LogProtocol  {
    
    public init() {}
    
    public func info(_ msg: String, _ params: Any...) {
        queue.async {
            DefaultLogger.printMsg(String(format: msg, params), prefix: Prefix.info)
        }
    }
    
    public func warning(_ msg: String, _ params: Any...) {
        queue.async {
            DefaultLogger.printMsg(String(format: msg, params), prefix: Prefix.warning)
        }
    }
    
    public func error(_ msg: String, _ params: Any...) {
        queue.async {
            DefaultLogger.printMsg(String(format: msg, params), prefix: Prefix.error)
        }
    }
    
    // MARK: -
    
    private struct Prefix {
        static let info = "👌[INFO]"
        static let warning = "⚠️[WARNING]"
        static let error = "❗️[ERROR]"
    }
    
    static func printMsg(_ msg: String, prefix: String) {
          print("\(prefix) \(msg)")
    }
    
    let queue = DispatchQueue(label: "log-queue", qos: .utility)
}
