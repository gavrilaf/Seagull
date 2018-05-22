import NIOHTTP1

public protocol ErrorProvider {
    func routerError(_ error: RouterError) -> SgErrorResponse
    func dataError(_ error: DataError) -> SgErrorResponse
    func generalError(_ error: Error) -> SgErrorResponse
}

extension ErrorProvider {
    func convert(error: Error) -> SgErrorResponse {
        switch error {
        case let errResp as SgErrorResponse:
            return errResp
        case let routerErr as RouterError:
            return routerError(routerErr)
        case let dataErr as DataError:
            return dataError(dataErr)
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
            return SgErrorResponse.appError(string: "Handler for \(method.str) \(uri) not found", code: .notFound)
        case .onlyOneWildAllowed:
            return SgErrorResponse.appError(string: "Only one wild allowed", code: .internalServerError)
        }
    }
    
    public func dataError(_ error: DataError) -> SgErrorResponse {
        switch error {
        case .emptyBody:
            return SgErrorResponse.appError(string: "Request has empty body", code: .badRequest)
        case .decodeErr(let err):
            return SgErrorResponse.appError(string: "JSON decoding error, \(err)", code: .badRequest)
        case .encodeErr(let err):
            return SgErrorResponse.appError(string: "JSON encoding error, \(err)", code: .internalServerError)
        }
    }

    public func generalError(_ error: Error) -> SgErrorResponse {
        return SgErrorResponse.appError(string: "Error: \(type(of: error)), \(error.localizedDescription)", code: .internalServerError)
    }
}
