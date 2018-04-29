import Foundation
import NIOHTTP1

public struct SgResponse {
    public let code: HTTPResponseStatus
    public let headers: HTTPHeaders
    public let body: Data?
}

public enum SgResult {
    case finished(response: SgResponse)
    case next(context: SgRequestContext)
}


extension SgResponse {
    public static func from(string: String) -> SgResponse {
        let headers = HTTPHeaders([("Content-Type", "text/plain")])
        return SgResponse(code: .ok, headers: headers, body: string.data(using: .utf8))
    }
    
    public static func from(error: Error) -> SgResponse {
        let headers = HTTPHeaders([("Content-Type", "text/plain")])
        let desc = "error: \(error)"
        return SgResponse(code: .ok, headers: headers, body: desc.data(using: .utf8))
    }
}

extension SgResult {
    public static func from(string: String) -> SgResult {
        return .finished(response: SgResponse.from(string: string))
    }
    
    public static func from(error: Error) -> SgResult {
        return .finished(response: SgResponse.from(error: error))
    }
}

