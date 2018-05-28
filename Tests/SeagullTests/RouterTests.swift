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
    
    // MARK: -
    static var allTests = [
        ("testStaticRoutes", testStaticRoutes),
        ("testMethods", testMethods),
        ("testParams", testParams),
        ("testGroup", testGroup)
    ]
}
