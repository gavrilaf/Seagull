import Foundation

public protocol LogProtocol {
    func info(_ msg: @autoclosure @escaping () -> String)
    func warning(_ msg: @autoclosure @escaping () -> String)
    func error(_ msg: @autoclosure @escaping () -> String)
}

///////////////////////////////////////////////////////////////////////////////////////////

public final class DefaultLogger: LogProtocol  {
    
    public init() {}
    
    public func info(_ msg: @autoclosure @escaping () -> String) {
        queue.async {
            DefaultLogger.printMsg(msg(), prefix: Prefix.info)
        }
    }
    
    public func warning(_ msg: @autoclosure @escaping () -> String) {
        queue.async {
            DefaultLogger.printMsg(msg(), prefix: Prefix.warning)
        }
    }
    
    public func error(_ msg: @autoclosure @escaping () -> String) {
        queue.async {
            DefaultLogger.printMsg(msg(), prefix: Prefix.error)
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


public final class EmptyLogger: LogProtocol  {
    
    public init() {}
    
    public func info(_ msg: @autoclosure @escaping () -> String) {
    }
    
    public func warning(_ msg: @autoclosure @escaping () -> String) {
    }
    
    public func error(_ msg: @autoclosure @escaping () -> String) {
    }
}
