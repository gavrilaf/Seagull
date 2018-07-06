import XCTest
import Result
import NIOHTTP1
@testable import Seagull

class RouterTests: XCTestCase {
    
    var router: Router!
    let emptyHandler: RequestHandler = { (_,_) in return SgResult.data(response: SgDataResponse.from(string: "")) }
    
    override func setUp() {
        router = Router()
    }
    
    func testStaticRoutes() {
        let routes = ["/", "/a", "/b", "/a/b/c/d/e/f", "/auth/register", "/auth/login"]
        routes.forEach { try! router.add(method: .GET, relativePath: $0, handler: emptyHandler) }
        
        routes.forEach { (path) in
            checkRoute(router.lookup(method: .GET, uri: path), path, .GET)
        }
    }

    func testMethods() {
        let methods: [HTTPMethod] = [.GET, .POST, .PUT, .DELETE]
        methods.forEach { try! router.add(method: $0, relativePath: "/", handler: emptyHandler) }
        
        methods.forEach { (method) in
            checkRoute(router.lookup(method: method, uri: "/"), "/", method)
        }
    }
    
    func testParams() {
        let routes = ["/user/:id", "/user/:id/:name", "/user/:id/vasya", "/auth/session/:id", "/:a/:b/:c/:d/:e/:f"]
        routes.forEach { try! router.add(method: .GET, relativePath: $0, handler: emptyHandler) }
        
        checkRoute(router.lookup(method: .GET, uri: "/user/id123"), "/user/:id", .GET, ["id": "id123"])
        checkRoute(router.lookup(method: .GET, uri: "/user/id123/petya"), "/user/:id/:name", .GET, ["id": "id123", "name": "petya"])
        checkRoute(router.lookup(method: .GET, uri: "/user/id123/vasya"), "/user/:id/vasya", .GET, ["id": "id123"])
        checkRoute(router.lookup(method: .GET, uri: "/auth/session/12"), "/auth/session/:id", .GET, ["id": "12"])
        checkRoute(router.lookup(method: .GET, uri: "/a/b/c/d/e/f"), "/:a/:b/:c/:d/:e/:f", .GET, ["a": "a", "b": "b", "c": "c", "d": "d", "e": "e", "f": "f"])
    }
    
    func testParamAllPath() {
        let routes = ["/file/*path", "/user/:id/*action"]
        routes.forEach { try! router.add(method: .GET, relativePath: $0, handler: emptyHandler) }
        
        checkRoute(router.lookup(method: .GET, uri: "/file/index.html"), "/file/*path", .GET, ["path": "index.html"])
        checkRoute(router.lookup(method: .GET, uri: "/file/static/index.html"), "/file/*path", .GET, ["path": "static/index.html"])
        checkRoute(router.lookup(method: .GET, uri: "/file/static/images/logo.png"), "/file/*path", .GET, ["path": "static/images/logo.png"])
        checkRoute(router.lookup(method: .GET, uri: "/user/vasya/send"), "/user/:id/*action", .GET, ["id": "vasya", "action": "send"])
        checkRoute(router.lookup(method: .GET, uri: "/user/vasya/add/country/usa"), "/user/:id/*action", .GET, ["id": "vasya", "action": "add/country/usa"])
    }
    
    func testRouterErrors() {
        checkRouterError(forPath: "/*action/send")
        checkRouterError(forPath: "/api/*action/send")
        checkRouterError(forPath: "/api/:id/*action/send")
        
        try! router.add(method: .GET, relativePath: "/user/:id", handler: emptyHandler)
        checkRouterError(forPath: "/user/:name/")
    }
    
    func testRoutesWithSlash() {
        let routes = ["/", "/:id", "/profile", "/profile/:id"]
        routes.forEach { try! router.add(method: .GET, relativePath: $0, handler: emptyHandler) }
        
        checkRoute(router.lookup(method: .GET, uri: "/"), "/", .GET)
        checkRoute(router.lookup(method: .GET, uri: "/id123"), "/:id", .GET, ["id": "id123"])
        checkRoute(router.lookup(method: .GET, uri: "/id123/"), "/:id", .GET, ["id": "id123"])
        checkRoute(router.lookup(method: .GET, uri: "/profile"), "/profile", .GET)
        checkRoute(router.lookup(method: .GET, uri: "/profile/id123"), "/profile/:id", .GET, ["id": "id123"])
        checkRoute(router.lookup(method: .GET, uri: "/profile/id123/"), "/profile/:id", .GET, ["id": "id123"])
    }
    
    func testGroup() {
        try! router.group("/auth") {
            try $0.PUT("/register", handler: self.emptyHandler)
            try $0.POST("/login", handler: self.emptyHandler)
        }
        
        try! router.group("/profile") {
            try $0.GET("/:id", handler: self.emptyHandler)
            try $0.GET("/:id/photo", handler: self.emptyHandler)
            try $0.POST("/:id", handler: self.emptyHandler)
        }
        
        checkRoute(router.lookup(method: .PUT, uri: "/auth/register"), "/auth/register", .PUT)
        checkRoute(router.lookup(method: .POST, uri: "/auth/login"), "/auth/login", .POST)
        checkRoute(router.lookup(method: .GET, uri: "/profile/123"), "/profile/:id", .GET, ["id": "123"])
        checkRoute(router.lookup(method: .GET, uri: "/profile/321/photo"), "/profile/:id/photo", .GET, ["id": "321"])
        checkRoute(router.lookup(method: .POST, uri: "/profile/9"), "/profile/:id", .POST, ["id": "9"])
    }

    // MARK: -
    func checkRoute(_ res: RouterResult, _ pattern: String, _ method: HTTPMethod, _ uriP: StringDict = [:], _ queryP: StringDict = [:]) {
        switch res {
        case .success(let value):
            XCTAssertEqual(pattern, value.pattern)
            XCTAssertEqual(method, value.method)
            XCTAssertEqual(uriP, value.urlParams)
            XCTAssertEqual(queryP, value.queryParams)
        case .failure(let err):
            XCTAssertFalse(true, "check route failed: \(method.str) : \(pattern), \(err)")
        }
    }
    
    func checkRouterError(forPath path: String) {
        XCTAssertThrowsError(try router.add(method: .GET, relativePath: path, handler: emptyHandler), "") { (err) in
            switch err {
            case RouterError.invalidPath(let errPath):
                XCTAssertEqual(path, errPath)
            default:
                XCTAssertTrue(false, "invalid router error")
            }
        }
    }
    
    // MARK: -
    static var allTests = [
        ("testStaticRoutes", testStaticRoutes),
        ("testMethods", testMethods),
        ("testParams", testParams),
        ("testParamAllPath", testParamAllPath),
        ("testRouterErrors", testRouterErrors),
        ("testRoutesWithSlash", testRoutesWithSlash),
        ("testGroup", testGroup)
    ]
}
