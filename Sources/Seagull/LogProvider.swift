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
    
    static let formatter: DateFormatter = {
        let dateFormatter =  DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
        return dateFormatter
    }()
    
    static func printMsg(_ msg: String, prefix: String) {
        print("\(prefix) \(formatter.string(from: Date())) - \(msg)")
    }
    
    let queue = DispatchQueue(label: "log-queue", qos: .utility)
}
