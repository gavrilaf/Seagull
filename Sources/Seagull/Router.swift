import Foundation
import NIOHTTP1
import Result

public struct Router {
    
    public init() {}
    
    public mutating func addHandler(forMethod method: HTTPMethod, relativePath: String, handlers: [RequestHandler]) {
        self.handlers[relativePath] = RouteHandler(handlers: handlers)
    }
    
    func getHandler(forUri uri: String, method: HTTPMethod) -> Result<RouteHandler, SgError> {
        if let handler = handlers[uri] {
            return Result(value: handler)
        }
        return Result(error: SgError(code: .notFound, text: "404 not found"))
    }
    
    var handlers = [String: RouteHandler]()
}
