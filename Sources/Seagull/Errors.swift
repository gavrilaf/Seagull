import Foundation
import NIO
import NIOHTTP1

// MARK: -

public protocol SgErrorProtocol: Error {}

public enum RouterError: SgErrorProtocol {
    case onlyOneWildAllowed
    case notFound(method: HTTPMethod, uri: String)
}

public enum DataError: SgErrorProtocol {
    case emptyBody
    case decodeErr(Error)
    case encodeErr(Error)
}

public enum AppCreatedError: SgErrorProtocol {
    case textErr(String)
    case jsonErr
}

// MARK: -

public struct SgErrorResponse: Error {
    public let response: SgDataResponse
    public let error: SgErrorProtocol
}

extension SgErrorResponse {
    
    public static func appError(string: String, code: HTTPResponseStatus, headers: HTTPHeaders = Headers.MIME.text) -> SgErrorResponse {
        let resp = SgDataResponse(code: code, headers: headers, body: string.data(using: .utf8))
        return SgErrorResponse(response: resp, error: AppCreatedError.textErr(string))
    }
    
    public static func appError<T: Encodable>(json: T, code: HTTPResponseStatus, headers: HTTPHeaders = Headers.MIME.json) throws -> SgErrorResponse {
        let encoder = JSONEncoder()
        let data = try encoder.encode(json)
        return SgErrorResponse(response: SgDataResponse(code: code, headers: headers, body: data), error: AppCreatedError.jsonErr)
    }
    
    public static func appError(dict: [String: Any], code: HTTPResponseStatus, headers: HTTPHeaders = Headers.MIME.json) throws -> SgErrorResponse {
        let data = try JSONSerialization.data(withJSONObject: dict, options: [])
        return SgErrorResponse(response: SgDataResponse(code: code, headers: headers, body: data), error: AppCreatedError.jsonErr)
    }
}
