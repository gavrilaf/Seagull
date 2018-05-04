import Foundation
import NIOHTTP1

struct RouteHandler {
    let middleware: MiddlewareChain
    let handler: RequestHandler
    
    init(middleware: MiddlewareChain, handler: @escaping RequestHandler) {
        self.middleware = middleware
        self.handler = handler
    }
    
    func handle(request: SgRequest) -> SgResult {
        let result = self.middleware.processMiddleware(request: request, context: SgRequestContext())
        switch result {
        case .success(let context):
            return handler(request, context)
        case .failure(let err):
            return SgResult.error(response: err)
        }
    }
}
