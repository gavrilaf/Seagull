import NIOHTTP1

public protocol ErrorProvider {
    func routerError(_ error: RouterError) -> SgErrorResponse
    func dataError(_ error: DataError) -> SgErrorResponse
    func generalError(_ error: Error) -> SgErrorResponse
}

extension ErrorProvider {
    func convert(error: Error) -> SgErrorResponse {
        switch error {
        case let err as SgErrorResponse:
            return err
        case let err as RouterError:
            return routerError(err)
        case let err as DataError:
            return dataError(err)
        default:
            return generalError(error)
        }
    }
}

// MARK: -

public final class DefaultErrorProvider: ErrorProvider {
    
    public init() {}
    
    public func routerError(_ error: RouterError) -> SgErrorResponse {
        switch error {
        case .notFound(let method, let uri):
            return SgErrorResponse.make(string: "Handler for \(method.str) \(uri) not found", code: .notFound, err: error)
        case .onlyOneWildAllowed:
            return SgErrorResponse.make(string: "Only one wild allowed", code: .internalServerError, err: error)
        }
    }
    
    public func dataError(_ error: DataError) -> SgErrorResponse {
        switch error {
        case .emptyBody:
            return SgErrorResponse.make(string: "Request has empty body", code: .badRequest, err: error)
        case .decodeErr(let err):
            return SgErrorResponse.make(string: "JSON decoding error, \(err)", code: .badRequest, err: error)
        case .encodeErr(let err):
            return SgErrorResponse.make(string: "JSON encoding error, \(err)", code: .internalServerError, err: error)
        }
    }
    
    public func generalError(_ error: Error) -> SgErrorResponse {
        return SgErrorResponse.make(string: "Error: \(type(of: error)), \(error.localizedDescription)", code: .internalServerError, err: error)
    }
}
