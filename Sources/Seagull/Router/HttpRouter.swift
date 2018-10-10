import SgRouter
import Result
import NIOHTTP1

public class HttpRouter {

    public init() {}
    
    public func add(handler: @escaping RequestHandler, for uri: String, method: HTTPMethod, with middleware: MiddlewareChain = []) throws {
        var handlers: HandlersMap! = try? router.lookup(uri: uri).value
        if handlers == nil {
            handlers = HandlersMap()
        }

        handlers.add(Handler(middleware: middleware, handler: handler), for: method)
        
        do {
            try router.add(relativePath: uri, value: handlers)
        } catch {
            throw RouterError.invalidPath(path: uri)
        }
    }
    
    public func lookup(uri: String, method: HTTPMethod) -> Result<RouteHandler, RouterError> {
        guard let r = try? router.lookup(uri: uri), let ph = r.value.get(for: method) else {
            return Result(error: RouterError.notFound(method: method, uri: uri))
        }
        
        let parsedRoute = ParsedRoute(pattern: r.pattern, uri: uri, method: method, uriParams: r.urlParams, queryParams: r.queryParams)
        let handler = RouteHandler(parsedRoute: parsedRoute, middleware: ph.middleware, handler: ph.handler)
        
        return Result(value: handler)
    }
  
    // MARK:-
    
    private struct Handler {
        let middleware: MiddlewareChain
        let handler: RequestHandler
    }
    
    private class HandlersMap {
        var handlers = [HTTPMethod: Handler]()
        
        func add(_ handler: Handler, for method: HTTPMethod) {
            handlers[method] = handler
        }
        
        func get(for method: HTTPMethod) -> Handler? {
            return handlers[method]
        }
    }
    
    private let router = Router<HandlersMap>()
}

extension HttpRouter {
    public func GET(_ uri: String, handler: @escaping RequestHandler, with middleware: MiddlewareChain = []) throws {
        try add(handler: handler, for: uri, method: .GET, with: middleware)
    }
    
    public func POST(_ uri: String, handler: @escaping RequestHandler, with middleware: MiddlewareChain = []) throws {
        try add(handler: handler, for: uri, method: .POST, with: middleware)
    }
    
    public func PUT(_ uri: String, handler: @escaping RequestHandler, with middleware: MiddlewareChain = []) throws {
        try add(handler: handler, for: uri, method: .PUT, with: middleware)
    }
    
    public func DELETE(_ uri: String, handler: @escaping RequestHandler, with middleware: MiddlewareChain = []) throws {
        try add(handler: handler, for: uri, method: .DELETE, with: middleware)
    }
}

extension HttpRouter {
    @discardableResult
    public func group(_ basePath: String, middleware: MiddlewareChain = [], initBlock: ((RouterGroup) throws -> Void)? = nil) throws -> RouterGroup {
        let group = RouterGroup(router: self, basePath: basePath, middleware: middleware)
        try initBlock?(group)
        return group
    }
}
