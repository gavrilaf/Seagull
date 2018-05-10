import Foundation
import NIOHTTP1
import Result

public enum RouterError: Error {
    case onlyOneWildAllowed
}

public final class Router {
    
    public init() {
        root = Node(name: "*")
    }
    
    public func add(method: HTTPMethod, relativePath: String, middleware: MiddlewareChain, handler: @escaping RequestHandler) throws {
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
    
    // MARK: - Internal
    
    struct ParsedPath {
        let pattern: String
        let urlParams: [String: String]
        let queryParams: [String: String]
        let middleware: MiddlewareChain
        let handler: RequestHandler
    }
    
    func lookup(method: HTTPMethod, uri: String) -> Result<ParsedPath, SgErrorResponse> {
        var current = root
        var urlParams = [String: String]()
        let components = PathBuilder(method: method, uri: uri).pathComponents
        
        for s in components {
            if let next = current.getChild(name: s) {
                current = next
            } else if let wild = current.wildChild {
                urlParams[wild.name] = s
                current = wild
            } else {
                return Result(error: notFoundError(method: method, uri: uri))
            }
        }
        
        if let pattern = current.pattern, let middleware = current.middleware, let handler = current.handler {
            let p = ParsedPath(pattern: pattern, urlParams: urlParams, queryParams: [:], middleware: middleware, handler: handler)
            return Result(value: p)
        }
        
        return Result(error: notFoundError(method: method, uri: uri))
    }
    
    func notFoundError(method: HTTPMethod, uri: String) -> SgErrorResponse {
        return SgErrorResponse.from(string: "Handler for \(method.str) : \(uri) not found", code: .notFound)
    }
    
    // MARK: - Private
    
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

