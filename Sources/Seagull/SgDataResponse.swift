import Foundation
import NIOHTTP1

public struct SgDataResponse {
    public let code: HTTPResponseStatus
    public let headers: HTTPHeaders
    public let body: Data?
}


extension SgDataResponse {
    public static func from(string: String, code: HTTPResponseStatus = .ok, headers: HTTPHeaders = Headers.MIME.text) -> SgDataResponse {
        return SgDataResponse(code: code, headers: headers, body: string.data(using: .utf8))
    }
    
    public static func from<T: Encodable>(json: T, code: HTTPResponseStatus = .ok, headers: HTTPHeaders = Headers.MIME.json) throws -> SgDataResponse {
        let encoder = JSONEncoder()
        let data = try encoder.encode(json)
        return SgDataResponse(code: code, headers: headers, body: data)
    }
    
    public static func from(dict: [String: Any], code: HTTPResponseStatus = .ok, headers: HTTPHeaders = Headers.MIME.json) throws -> SgDataResponse {
        let data = try JSONSerialization.data(withJSONObject: dict, options: [])
        return SgDataResponse(code: code, headers: headers, body: data)
    }
}




