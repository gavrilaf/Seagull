import Foundation
import NIO
import NIOHTTP1

// MARK: -

public enum DataError: LocalizedError {
    case emptyBody
    case decodeErr(Error)
    case encodeErr(Error)
    
    public var errorDescription: String? {
        switch self {
        case .emptyBody:
            return "DataError.emptyBody"
        case .decodeErr(let err):
            return "DataError.decodeErr(\(err))"
        case .encodeErr(let err):
            return "DataError.encodeErr(\(err))"
        }
    }
}

public enum RouterError: LocalizedError {
    case onlyOneWildAllowed
    case notFound(method: HTTPMethod, uri: String)
    
    public var errorDescription: String? {
        switch self {
        case .onlyOneWildAllowed:
            return "RouterError.onlyOneWildAllowed"
        case .notFound(let method, let uri):
            return "RouterError.notFound(\(method), \(uri))"
        }
    }
}

// MARK: -

public struct SgErrorResponse: Error {
    public let response: SgDataResponse
    public let error: Error?
}

extension SgErrorResponse {
    
    public static func make(string: String, code: HTTPResponseStatus, headers: HTTPHeaders = Headers.MIME.text, err: Error? = nil) -> SgErrorResponse {
        let resp = SgDataResponse(code: code, headers: headers, body: string.data(using: .utf8))
        return SgErrorResponse(response: resp, error: err)
    }
    
    public static func make<T: Encodable>(json: T, code: HTTPResponseStatus, headers: HTTPHeaders = Headers.MIME.json, err: Error? = nil) throws -> SgErrorResponse {
        let data = try JSONEncoder().encode(json)
        return SgErrorResponse(response: SgDataResponse(code: code, headers: headers, body: data), error: err )
    }
    
    public static func make(dict: [String: Any], code: HTTPResponseStatus, headers: HTTPHeaders = Headers.MIME.json, err: Error? = nil) throws -> SgErrorResponse {
        let data = try JSONSerialization.data(withJSONObject: dict, options: [])
        return SgErrorResponse(response: SgDataResponse(code: code, headers: headers, body: data), error: err)
    }
}
