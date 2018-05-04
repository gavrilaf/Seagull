import Foundation
import NIO
import NIOHTTP1

public struct SgErrorResponse: Error {
    public let response: SgDataResponse
}

extension SgErrorResponse {
    public static func from(string: String, code: HTTPResponseStatus, headers: HTTPHeaders = Headers.MIME.text) -> SgErrorResponse {
        return SgErrorResponse(response: SgDataResponse(code: code, headers: headers, body: string.data(using: .utf8)))
    }
    
    public static func from<T: Encodable>(json: T, code: HTTPResponseStatus, headers: HTTPHeaders = Headers.MIME.json) -> SgErrorResponse {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(json)
            return SgErrorResponse(response: SgDataResponse(code: code, headers: headers, body: data))
        } catch let error {
            return SgErrorResponse.from(error: error)
        }
    }
    
    public static func from(dict: [String: Any], code: HTTPResponseStatus, headers: HTTPHeaders = Headers.MIME.json) -> SgErrorResponse {
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            return SgErrorResponse(response: SgDataResponse(code: code, headers: headers, body: data))
        } catch let error {
            return SgErrorResponse.from(error: error)
        }
    }
    
    public static func from(error: Error, code: HTTPResponseStatus = .internalServerError, headers: HTTPHeaders = Headers.MIME.text) -> SgErrorResponse {
        var errTxt = ""
        var errCode = code
        
        switch error {
        case let e as IOError where e.errnoCode == ENOENT:
            errTxt = "IOError (not found)"
            errCode = .notFound
        case let e as IOError:
            errTxt = "IOError \(e.description)"
            errCode = .notFound
        default:
            errTxt = "Error: \(error)"
        }
        
        return SgErrorResponse(response: SgDataResponse(code: errCode, headers: headers, body: errTxt.data(using: .utf8)))
    }
}
