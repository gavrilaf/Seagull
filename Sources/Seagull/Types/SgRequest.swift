import Foundation
import NIO
import NIOHTTP1

public struct RequestExtra {
    public let headers: HTTPHeaders
    public let body: Data?
}

extension RequestExtra {
    static func make(from head: HTTPRequestHead, body: ByteBuffer?) -> RequestExtra {
        var data: Data? = nil
        if let body = body {
            data = body.withUnsafeReadableBytes { (bufPointer) -> Data in
                return Data(bufPointer)
            }
        }
        
        return RequestExtra(headers: head.headers, body: data)
    }
}

// MARK:-

public struct SgRequest {
    public let route: ParsedRoute
    public let extra: RequestExtra
}
