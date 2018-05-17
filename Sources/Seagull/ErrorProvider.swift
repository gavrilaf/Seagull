import NIOHTTP1

public protocol ErrorProvider {
    func notFoundError(method: HTTPMethod, uri: String) -> SgErrorResponse
    func generalError(_ error: Error) -> SgErrorResponse
}

extension ErrorProvider {
    func convert(error: Error) -> SgErrorResponse {
        switch error {
        case RouterError.notFound(let method, let uri):
            return notFoundError(method: method, uri: uri)
        default:
            return generalError(error)
        }
    }
}

// MARK: -

public final class DefaultErrorProvider: ErrorProvider {
    
    public init() {}
    
    public func notFoundError(method: HTTPMethod, uri: String) -> SgErrorResponse {
        return SgErrorResponse.from(string: "Handler for \(method.str) \(uri) not found", code: .notFound)
    }
    
    public func generalError(_ error: Error) -> SgErrorResponse {
        return SgErrorResponse.from(string: "Error: \(type(of: error)), \(error.localizedDescription)", code: .internalServerError)
    }
}
