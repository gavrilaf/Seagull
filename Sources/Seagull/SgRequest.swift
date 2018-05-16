import Foundation
import NIO
import NIOHTTP1

public struct SgRequest {
    public let pattern: String
    public let uri: String
    public let method: HTTPMethod
    public let headers: HTTPHeaders
    public let urlParams: [String: String]
    public let queryParams: [String: String]
    public let body: Data?
}

extension SgRequest {
    static func from(preparedRequest: PreparedRequest, head: HTTPRequestHead, body: ByteBuffer?) -> SgRequest {
        
        let data: Data?
        if let body = body {
            data = body.withUnsafeReadableBytes { (bufPointer) -> Data in
                return Data(bufPointer)
            }
        } else {
            data = nil
        }
        
        return SgRequest(pattern: preparedRequest.pattern,
                         uri: head.uri,
                         method: head.method,
                         headers: head.headers,
                         urlParams: preparedRequest.urlParams,
                         queryParams: preparedRequest.queryParams,
                         body: data)
    }
}

public struct SgRequestContext {
    public var userInfo: [String: Any]
    
    init() {
        userInfo = [:]
    }
}

