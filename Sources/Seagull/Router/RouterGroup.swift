import NIOHTTP1

public final class RouterGroup {
    
    init(router: HttpRouter, basePath: String, middleware: MiddlewareChain) {
        self.router = router
        self.basePath = basePath
        self.commonMiddleware = middleware
    }
    
    public func add(handler: @escaping RequestHandler, for uri: String, method: HTTPMethod, with middleware: MiddlewareChain = []) throws {
        try router.add(handler: handler, for: self.basePath + uri, method: method, with: self.commonMiddleware + middleware)
    }
    
    public func GET(_ uri: String, handler: @escaping RequestHandler, middleware: MiddlewareChain = []) throws {
        try add(handler: handler, for: uri, method: .GET, with: middleware)
    }
    
    public func POST(_ uri: String, handler: @escaping RequestHandler, middleware: MiddlewareChain = []) throws {
        try add(handler: handler, for: uri, method: .POST, with: middleware)
    }
    
    public func PUT(_ uri: String, handler: @escaping RequestHandler, middleware: MiddlewareChain = []) throws {
        try add(handler: handler, for: uri, method: .PUT, with: middleware)
    }
    
    public func DELETE(_ uri: String, handler: @escaping RequestHandler, middleware: MiddlewareChain = []) throws {
        try add(handler: handler, for: uri, method: .DELETE, with: middleware)
    }
    
    // MARK: -
    private let router: HttpRouter
    private let basePath: String
    private let commonMiddleware: MiddlewareChain
}
