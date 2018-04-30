import Foundation
import NIOHTTP1
import Result

public struct SgError: Error {
    public let code: HTTPResponseStatus
    public let text: String
}

public typealias MiddlewareResult = Result<SgRequestContext, SgError>
public typealias MiddlewareHandler = (SgRequest, SgRequestContext) -> MiddlewareResult
public typealias MiddlewareChain = [MiddlewareHandler]

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

public typealias RequestHandler = (SgRequest, SgRequestContext) -> SgResult


