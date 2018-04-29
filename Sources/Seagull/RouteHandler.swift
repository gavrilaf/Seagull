import Foundation
import NIOHTTP1

struct RouteHandler {
    
    let handlers: [RequestHandler]
    
    init(handlers: [RequestHandler]) {
        self.handlers = handlers
    }
    
    func handle(request: SgRequest) -> SgResponse {
        
        var currentContext = SgRequestContext()
        
        for handler in handlers {
            let res = handler(request, currentContext)
            switch res {
            case .finished(let response):
                return response
            case .next(let context):
                currentContext = context
            }
        }
        
        return SgResponse.from(error: SgError(code: .internalServerError, text: "invalid handlers chain"))
    }
}
