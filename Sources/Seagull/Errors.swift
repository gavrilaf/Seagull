import Foundation
import NIO
import NIOHTTP1

public enum AppLogicError: Error {
    case textError(String)
    case jsonError
}

public struct SgErrorResponse: Error {
    public let response: SgDataResponse
    public let error: Error
}

extension SgErrorResponse {
    
    public static func from(string: String, code: HTTPResponseStatus, headers: HTTPHeaders = Headers.MIME.text) -> SgErrorResponse {
        let resp = SgDataResponse(code: code, headers: headers, body: string.data(using: .utf8))
        return SgErrorResponse(response: resp, error: AppLogicError.textError(string))
    }
    
    public static func from<T: Encodable>(json: T, code: HTTPResponseStatus, headers: HTTPHeaders = Headers.MIME.json) throws -> SgErrorResponse {
        let encoder = JSONEncoder()
        let data = try encoder.encode(json)
        return SgErrorResponse(response: SgDataResponse(code: code, headers: headers, body: data), error: AppLogicError.jsonError)
    }
    
    public static func from(dict: [String: Any], code: HTTPResponseStatus, headers: HTTPHeaders = Headers.MIME.json) throws -> SgErrorResponse {
        let data = try JSONSerialization.data(withJSONObject: dict, options: [])
        return SgErrorResponse(response: SgDataResponse(code: code, headers: headers, body: data), error: AppLogicError.jsonError)
    }
}
