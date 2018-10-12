import Foundation
import NIOHTTP1

public struct Headers {
    public struct MIME {
        public static let text = HTTPHeaders([("Content-Type", "text/plain")])
        public static let json = HTTPHeaders([("Content-Type", "application/json")])
        public static let octetStream = HTTPHeaders([("Content-Type", "application/octet-stream")])
        public static let html = HTTPHeaders([("Content-Type", "text/html")])
        public static let jpg = HTTPHeaders([("Content-Type", "image/jpg")])
    }
}

// MARK: -

extension HTTPMethod: Hashable {
    public var hashValue: Int {
        switch self {
        case .GET:
            return 1
        case .PUT:
            return 2
        case .ACL:
            return 3
        case .HEAD:
            return 4
        case .POST:
            return 5
        case .COPY:
            return 6
        case .LOCK:
            return 7
        case .MOVE:
            return 8
        case .BIND:
            return 9
        case .LINK:
            return 10
        case .PATCH:
            return 11
        case .TRACE:
            return 12
        case .MKCOL:
            return 13
        case .MERGE:
            return 14
        case .PURGE:
            return 15
        case .NOTIFY:
            return 16
        case .SEARCH:
            return 17
        case .UNLOCK:
            return 18
        case .REBIND:
            return 19
        case .UNBIND:
            return 20
        case .REPORT:
            return 21
        case .DELETE:
            return 22
        case .UNLINK:
            return 23
        case .CONNECT:
            return 24
        case .MSEARCH:
            return 25
        case .OPTIONS:
            return 26
        case .PROPFIND:
            return 27
        case .CHECKOUT:
            return 28
        case .PROPPATCH:
            return 29
        case .SUBSCRIBE:
            return 30
        case .MKCALENDAR:
            return 31
        case .MKACTIVITY:
            return 32
        case .UNSUBSCRIBE:
            return 33
        case .RAW(let value):
            return 34 + value.hashValue
        }
    }
}

extension HTTPMethod {
    public var str: String {
        switch self {
        case .GET:
            return "GET"
        case .PUT:
            return "PUT"
        case .ACL:
            return "ACL"
        case .HEAD:
            return "HEAD"
        case .POST:
            return "POST"
        case .COPY:
            return "COPY"
        case .LOCK:
            return "LOCK"
        case .MOVE:
            return "MOVE"
        case .BIND:
            return "BIND"
        case .LINK:
            return "LINK"
        case .PATCH:
            return "PATH"
        case .TRACE:
            return "TRACE"
        case .MKCOL:
            return "MKCOL"
        case .MERGE:
            return "MERGE"
        case .PURGE:
            return "PURGE"
        case .NOTIFY:
            return "NOTIFY"
        case .SEARCH:
            return "SEARCH"
        case .UNLOCK:
            return "UNLOCK"
        case .REBIND:
            return "REBIND"
        case .UNBIND:
            return "UNBIND"
        case .REPORT:
            return "REPORT"
        case .DELETE:
            return "DELETE"
        case .UNLINK:
            return "UNLINK"
        case .CONNECT:
            return "CONNECT"
        case .MSEARCH:
            return "MSEARCH"
        case .OPTIONS:
            return "OPTIONS"
        case .PROPFIND:
            return "PROPFIND"
        case .CHECKOUT:
            return "CHECKOUT"
        case .PROPPATCH:
            return "PROPPATCH"
        case .SUBSCRIBE:
            return "SUBSCRIBE"
        case .MKCALENDAR:
            return "MKCALENDAR"
        case .MKACTIVITY:
            return "MKACTIVITY"
        case .UNSUBSCRIBE:
            return "UNSUBSCRIBE"
        case .RAW(let value):
            return "RAW(\(value))"
        }
    }
}
