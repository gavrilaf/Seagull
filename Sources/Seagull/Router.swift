import Foundation
import NIOHTTP1
import Result

public struct Router {
    
    public init() {}
    
    public mutating func addHandler(forMethod method: HTTPMethod, relativePath: String, handler: @escaping RequestHandler, middleware: MiddlewareChain = []) {
        self.handlers[relativePath] = RouteHandler(middleware: middleware, handler: handler)
    }
    
    func getHandler(forUri uri: String, method: HTTPMethod) -> Result<RouteHandler, SgErrorResponse> {
        if let handler = handlers[uri] {
            return Result(value: handler)
        }
        return Result(error: SgErrorResponse.from(string: "Route for \(method) \(uri) not found", code: .notFound))
    }
    
    var handlers = [String: RouteHandler]()
}
