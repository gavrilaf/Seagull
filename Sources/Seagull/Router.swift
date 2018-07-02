import Foundation
import NIOHTTP1
import Result

public typealias StringDict = [String: String]

public struct PreparedRequest {
    public let uri: String
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
    
    @discardableResult
    public func group(_ relativePath: String, middleware: MiddlewareChain = [], initBlock: ((RouterGroup) throws -> Void)? = nil) throws -> RouterGroup {
        let group = RouterGroup(router: self, relativePath: relativePath, middleware: middleware)
        try initBlock?(group)
        return group
    }
    
    public func add(method: HTTPMethod, relativePath: String, handler: @escaping RequestHandler, middleware: MiddlewareChain = []) throws {
        var current = root
        let components = PathBuilder(method: method, uri: relativePath).pathComponents
        
        for s in components {
            if s.hasPrefix(":") || s.hasPrefix("*") { // param
                let paramName = s.dropFirst() //String(s.dropFirst())
                if let paramChild = current.paramChild {
                    if paramChild.name == paramName {
                        current = paramChild
                    } else {
                        throw RouterError.onlyOneWildAllowed
                    }
                } else {
                    let newNode = Node(name: String(paramName), allPath: s.hasPrefix("*"))
                    current.paramChild = newNode
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
        
        for (indx, s) in components.enumerated() {
            if let next = current.getChild(name: s) {
                current = next
            } else if let paramChild = current.paramChild {
                if paramChild.allPath {
                    urlParams[paramChild.name] = components[indx..<components.count-1].joined(separator: "/")
                    if let methodChild = paramChild.getChild(name: method.str) {
                        current = methodChild
                        break
                    } else {
                        return Result(error: RouterError.notFound(method: method, uri: uri))
                    }
                } else {
                    urlParams[paramChild.name] = s
                    current = paramChild
                }
            } else {
                return Result(error: RouterError.notFound(method: method, uri: uri))
            }
        }
        
        if let pattern = current.pattern, let middleware = current.middleware, let handler = current.handler {
            let p = PreparedRequest(uri: uri,
                                    pattern: pattern,
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
        init(name: String, allPath: Bool = false) {
            self.name = name
            self.allPath = allPath
        }
        
        let name: String
        let allPath: Bool
        
        var paramChild: Node?
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

