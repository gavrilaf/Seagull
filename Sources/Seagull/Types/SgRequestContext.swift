import Foundation
import Result
import NIOHTTP1

public struct SgRequestContext {
    
    public let logger: LogProtocol
    public let errorProvider: ErrorProvider
    
    init(logger: LogProtocol, errorProvider: ErrorProvider) {
        self.logger = logger
        self.errorProvider = errorProvider
        
        _userInfo = [:]
    }
    
    public mutating func set(value: Any, forKey key: String) {
        _userInfo[key] = value
    }
    
    public var userInfo: [String: Any] {
        return _userInfo
    }
    
    public func string(forKey key: String) -> String {
        return _userInfo[key] as? String ?? ""
    }
    
    // MARK:-
    private var _userInfo: [String: Any]
}

extension SgRequestContext {
    
    // MARK:-
    public func decode<T: Decodable>(_ t: T.Type, request: SgRequest) throws -> T {
        guard let body = request.extra.body else {
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
    
    // MARK:-
    public func error(_ error: Error) -> SgResult {
        return SgResult.error(response: errorProvider.convert(error: error))
    }
    
    // MARK:-
    public func empty(code: HTTPResponseStatus = .ok, headers: HTTPHeaders = HTTPHeaders()) -> SgResult {
        return SgResult.data(response: SgDataResponse.empty(code: code, headers: headers))
    }
    
    public func text(_ text: String, code: HTTPResponseStatus = .ok, headers: HTTPHeaders = HTTPHeaders()) -> SgResult {
        return SgResult.data(response: SgDataResponse.from(string: text, code: code, headers: headers))
    }
}
