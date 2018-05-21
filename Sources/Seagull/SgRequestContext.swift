import Foundation
import Result
import NIOHTTP1

public struct SgRequestContext {
    public var userInfo: [String: Any]
    
    public let logger: LogProtocol
    public let errorProvider: ErrorProvider
    
    init(logger: LogProtocol, errorProvider: ErrorProvider) {
        self.logger = logger
        self.errorProvider = errorProvider
        
        userInfo = [:]
    }
}

enum ConvertError: Error {
    case emptyBody
    case decodeErr(Error)
    case encodeErr(Error)
}

extension SgRequestContext {
    public func decode<T: Decodable>(_ t: T.Type, request: SgRequest) throws -> T {
        guard let body = request.body else {
            throw ConvertError.emptyBody
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: body)
        } catch let err {
            throw ConvertError.decodeErr(err)
        }
    }
    
    public func encode<T: Encodable>(json: T, code: HTTPResponseStatus = .ok, headers: HTTPHeaders = Headers.MIME.json) -> SgResult {
        do {
            return SgResult.data(response: try SgDataResponse.from(json: json, code: code, headers: headers))
        } catch let err {
            return SgResult.error(response: errorProvider.generalError(ConvertError.decodeErr(err)))
        }
    }
    
    public func encode(dict: [String: Any], code: HTTPResponseStatus = .ok, headers: HTTPHeaders = Headers.MIME.json) -> SgResult {
        do {
            return SgResult.data(response: try SgDataResponse.from(dict: dict, code: code, headers: headers))
        } catch let err {
            return SgResult.error(response: errorProvider.generalError(ConvertError.decodeErr(err)))
        }
    }
}
