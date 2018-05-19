import NIOHTTP1

public final class RouterGroup {
    
    init(router: Router, relativePath: String, middleware: MiddlewareChain) {
        self.router = router
        self.relativePath = relativePath
        self.middleware = middleware
    }
    
    public func add(method: HTTPMethod, relativePath: String, handler: @escaping RequestHandler, middleware: MiddlewareChain = []) throws {
        try router.add(method: method, relativePath: self.relativePath + relativePath, handler: handler, middleware: self.middleware + middleware)
    }
    
    // MARK: -
    private let router: Router
    private let relativePath: String
    private let middleware: MiddlewareChain
}
