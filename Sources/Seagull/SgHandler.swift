import Foundation
import NIOHTTP1
import Result

public typealias RequestHandler = (SgRequest, SgRequestContext) -> SgResult

public typealias MiddlewareResult = Result<SgRequestContext, SgErrorResponse>
public typealias MiddlewareHandler = (SgRequest, SgRequestContext) -> MiddlewareResult
public typealias MiddlewareChain = [MiddlewareHandler]

// MARK: -

extension Array where Element == MiddlewareHandler {
    func processMiddleware(request: SgRequest, context: SgRequestContext) -> MiddlewareResult {
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

extension PreparedRequest {
    func handle(request: SgRequest, ctx: SgRequestContext) -> SgResult {
        switch self.middleware.processMiddleware(request: request, context: ctx) {
        case .success(let ctx):
            return self.handler(request, ctx)
        case .failure(let err):
            return SgResult.error(response: err)
        }
    }
}

