import Foundation
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
    static func from(parsedPath: ParsedPath, request: HTTPRequestHead) -> SgRequest {
        return SgRequest(pattern: parsedPath.pattern,
                         uri: request.uri,
                         method: request.method,
                         headers: request.headers,
                         urlParams: parsedPath.urlParams,
                         queryParams: parsedPath.queryParams,
                         body: nil)
    }
}

public struct SgRequestContext {
    public var userInfo: [String: Any]
    
    init() {
        userInfo = [:]
    }
}

