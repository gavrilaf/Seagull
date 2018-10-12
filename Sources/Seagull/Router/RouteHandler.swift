import Foundation
import NIOHTTP1
import Result

public typealias RequestHandler = (SgRequest, SgRequestContext) -> SgResult

public typealias MiddlewareResult = Result<SgRequestContext, SgErrorResponse>
public typealias MiddlewareHandler = (SgRequest, SgRequestContext) -> MiddlewareResult


// MARK: -
public typealias MiddlewareChain = [MiddlewareHandler]

extension Array where Element == MiddlewareHandler {
    func processMiddleware(request: SgRequest, with context: SgRequestContext) -> MiddlewareResult {
        var currentContext = context
        for f in self {
            let res = f(request, currentContext)
            switch res {
            case .failure(let err):
                return MiddlewareResult(error: err)
            case .success(let context):
                currentContext = context
            }
        }
        return MiddlewareResult(value: currentContext)
    }
}

// MARK: -

public struct ParsedRoute {
    public let pattern: String
    
    public let uri: String
    public let method: HTTPMethod
    
    public let uriParams: [Substring: Substring]
    public let queryParams: [Substring: Substring]
}

public struct RouteHandler {
    public let parsedRoute: ParsedRoute

    public let middleware: MiddlewareChain
    public let handler: RequestHandler
}

extension RouteHandler {
    func handle(request: SgRequest, with context: SgRequestContext) -> SgResult {
        switch self.middleware.processMiddleware(request: request, with: context) {
        case .success(let context):
            return self.handler(request, context)
        case .failure(let err):
            return .error(response: err)
        }
    }
}

