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

// MARK: -

extension SgRequestContext {
    public func decode<T: Decodable>(_ t: T.Type, request: SgRequest) throws -> T {
        guard let body = request.body else {
            throw DataError.emptyBody
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: body)
        } catch let err {
            throw DataError.decodeErr(err)
        }
    }
    
    public func encode<T: Encodable>(json: T, code: HTTPResponseStatus = .ok, headers: HTTPHeaders = Headers.MIME.json) -> SgResult {
        do {
            return SgResult.data(response: try SgDataResponse.from(json: json, code: code, headers: headers))
        } catch let err {
            return SgResult.error(response: errorProvider.convert(error: DataError.decodeErr(err)))
        }
    }
    
    public func encode(dict: [String: Any], code: HTTPResponseStatus = .ok, headers: HTTPHeaders = Headers.MIME.json) -> SgResult {
        do {
            return SgResult.data(response: try SgDataResponse.from(dict: dict, code: code, headers: headers))
        } catch let err {
            return SgResult.error(response: errorProvider.convert(error: DataError.encodeErr(err)))
        }
    }
}
