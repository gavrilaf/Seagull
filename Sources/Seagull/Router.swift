import Foundation
import NIOHTTP1
import Result

public enum RouterError: Error {
    case onlyOneWildAllowed
    case notFound(method: HTTPMethod, uri: String)
}

public typealias StringDict = [String: String]

public struct PreparedRequest {
    public let pattern: String
    public let method: HTTPMethod
    public let urlParams: StringDict
    public let queryParams: StringDict
    public let middleware: MiddlewareChain
    public let handler: RequestHandler
}

public typealias RouterResult = Result<PreparedRequest, RouterError>

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public final class Router {
    public init() {
        root = Node(name: "*")
    }
    
    public func group(relativePath: String, middleware: MiddlewareChain = []) -> RouterGroup {
        return RouterGroup(router: self, relativePath: relativePath, middleware: middleware)
    }
    
    public func add(method: HTTPMethod, relativePath: String, handler: @escaping RequestHandler, middleware: MiddlewareChain = []) throws {
        var current = root
        let components = PathBuilder(method: method, uri: relativePath).pathComponents
        
        for s in components {
            if s.hasPrefix(":") { // wild
                let wildName = String(s.dropFirst())
                if let wild = current.wildChild {
                    if wild.name == wildName {
                        current = wild
                    } else {
                        throw RouterError.onlyOneWildAllowed
                    }
                } else {
                    let newNode = Node(name: wildName)
                    current.wildChild = newNode
                    current = newNode
                }
            } else {
                if let next = current.getChild(name: s) {
                    current = next
                } else {
                    let newNode = Node(name: s)
                    current.addChild(node: newNode)
                    current = newNode
                }
            }
        }
        
        current.pattern = relativePath
        current.middleware = middleware
        current.handler = handler
    }
    
    public func lookup(method: HTTPMethod, uri: String) -> RouterResult {
        var current = root
        var urlParams = StringDict()
        let components = PathBuilder(method: method, uri: uri).pathComponents
        
        for s in components {
            if let next = current.getChild(name: s) {
                current = next
            } else if let wild = current.wildChild {
                urlParams[wild.name] = s
                current = wild
            } else {
                return Result(error: RouterError.notFound(method: method, uri: uri))
            }
        }
        
        if let pattern = current.pattern, let middleware = current.middleware, let handler = current.handler {
            let p = PreparedRequest(pattern: pattern,
                                    method: method,
                                    urlParams: urlParams,
                                    queryParams: [:],
                                    middleware: middleware,
                                    handler: handler)
            
            return Result(value: p)
        }
        
        return Result(error: RouterError.notFound(method: method, uri: uri))
    }
    
    // MARK: -
    
    private final class Node {
        init(name: String) {
            self.name = name
        }
        
        let name: String
        
        var wildChild: Node?
        var children = Dictionary<String, Node>()
        
        var pattern: String?
        var middleware: MiddlewareChain?
        var handler: RequestHandler?
        
        func addChild(node: Node) {
            children[node.name] = node
        }
        
        func getChild(name: String) -> Node? {
            return children[name]
        }
    }
    
    private var root: Node
}

