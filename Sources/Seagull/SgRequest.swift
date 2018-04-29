import Foundation
import NIOHTTP1

public struct SgRequest {
    public let pattern: String
    public let uri: String
    public let method: HTTPMethod
    public let headers: HTTPHeaders
    public let body: Data?
}

public struct SgRequestContext {
    public var userInfo: [String: Any]
    
    init() {
        userInfo = [:]
    }
}

