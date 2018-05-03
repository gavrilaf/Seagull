import Foundation
import NIOHTTP1

public struct SgDataResponse {
    public let code: HTTPResponseStatus
    public let headers: HTTPHeaders
    public let body: Data?
}

public struct SgFileResponse {
    public let code: HTTPResponseStatus
    public let headers: HTTPHeaders
    public let path: String
}


extension SgDataResponse {
    public static func from(string: String) -> SgDataResponse {
        let headers = HTTPHeaders([("Content-Type", "text/plain")])
        return SgDataResponse(code: .ok, headers: headers, body: string.data(using: .utf8))
    }
    
    public static func from(error: Error) -> SgDataResponse {
        let headers = HTTPHeaders([("Content-Type", "text/plain")])
        let desc = "error: \(error)"
        return SgDataResponse(code: .ok, headers: headers, body: desc.data(using: .utf8))
    }
}


 extension SgFileResponse {
    public static func from(path: String) -> SgFileResponse {
        return SgFileResponse(code: .ok, headers: HTTPHeaders(), path: path)
    }
}


