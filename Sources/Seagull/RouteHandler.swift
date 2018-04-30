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
        
        var currentContext = SgRequestContext()
        
        for middleware in middleware {
            let res = middleware(request, currentContext)
            switch res {
            case .failure(let err):
                return SgResult.from(error: err)
            case .success(let context):
                currentContext = context
            }
        }
        
        return handler(request, currentContext)
    }
}
