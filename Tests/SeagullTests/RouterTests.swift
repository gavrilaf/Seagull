import XCTest
import Result
import NIOHTTP1
@testable import Seagull

class RouterTests: XCTestCase {
    
    var router: HttpRouter!
    let emptyHandler: RequestHandler = { (_,_) in return SgResult.data(response: SgDataResponse.from(string: "")) }
    
    override func setUp() {
        router = HttpRouter()
    }
    
    func testStaticRoutes() {
        let routes = ["/", "/a", "/b", "/a/b/c/d/e/f", "/auth/register", "/auth/login"]
        routes.forEach { try! router.GET($0, handler: emptyHandler) }
        
        AssertRouteFound(router.lookup(uri: "/", method: .GET), "/", .GET)
        AssertRouteFound(router.lookup(uri: "/a", method: .GET), "/a", .GET)
        AssertRouteFound(router.lookup(uri: "/b", method: .GET), "/b", .GET)
        AssertRouteFound(router.lookup(uri: "/a/b/c/d/e/f", method: .GET), "/a/b/c/d/e/f", .GET)
        AssertRouteFound(router.lookup(uri: "/auth/register", method: .GET), "/auth/register", .GET)
        AssertRouteFound(router.lookup(uri: "/auth/login", method: .GET), "/auth/login", .GET)
    }

    func testMethods() {
        let methods: [HTTPMethod] = [.GET, .POST, .PUT, .DELETE]
        methods.forEach { try! router.add(handler: emptyHandler, for: "/", method: $0) }
        
        AssertRouteFound(router.lookup(uri: "/", method: .GET), "/", .GET)
        AssertRouteFound(router.lookup(uri: "/", method: .POST), "/", .POST)
        AssertRouteFound(router.lookup(uri: "/", method: .PUT), "/", .PUT)
        AssertRouteFound(router.lookup(uri: "/", method: .DELETE), "/", .DELETE)
    }
    
    func testParams() {
        let routes = ["/user/:id", "/user/:id/:name", "/user/:id/vasya", "/auth/session/:id", "/:a/:b/:c/:d/:e/:f"]
        routes.forEach { try! router.GET($0, handler: emptyHandler) }
        
        AssertRouteFound(router.lookup(uri: "/user/id123", method: .GET), "/user/:id", .GET, ["id": "id123"])
        AssertRouteFound(router.lookup(uri: "/user/id123/petya", method: .GET), "/user/:id/:name", .GET, ["id": "id123", "name": "petya"])
        AssertRouteFound(router.lookup(uri: "/user/id123/vasya", method: .GET), "/user/:id/vasya", .GET, ["id": "id123"])
        AssertRouteFound(router.lookup(uri: "/auth/session/12", method: .GET), "/auth/session/:id", .GET, ["id": "12"])
        AssertRouteFound(router.lookup(uri: "/a/b/c/d/e/f", method: .GET), "/:a/:b/:c/:d/:e/:f", .GET, ["a": "a", "b": "b", "c": "c", "d": "d", "e": "e", "f": "f"])
    }
    
    func testParamAllPath() {
        let routes = ["/file/*path", "/user/:id/*action"]
        routes.forEach { try! router.GET($0, handler: emptyHandler) }
        
        AssertRouteFound(router.lookup(uri: "/file/index.html", method: .GET), "/file/*path", .GET, ["path": "index.html"])
        AssertRouteFound(router.lookup(uri: "/file/static/index.html", method: .GET), "/file/*path", .GET, ["path": "static/index.html"])
        AssertRouteFound(router.lookup(uri: "/file/static/images/logo.png", method: .GET), "/file/*path", .GET, ["path": "static/images/logo.png"])
        AssertRouteFound(router.lookup(uri: "/user/vasya/send", method: .GET), "/user/:id/*action", .GET, ["id": "vasya", "action": "send"])
        AssertRouteFound(router.lookup(uri: "/user/vasya/add/country/usa", method: .GET), "/user/:id/*action", .GET, ["id": "vasya", "action": "add/country/usa"])
    }
    
    func testRouterErrors() {
        try! router.GET("/api/*action/send", handler: emptyHandler)
        try! router.GET("/user/:id", handler: emptyHandler)
        
        AssertAddRouteError(router,  "/api/:id/*action/send")
        AssertAddRouteError(router,  "/user/:name/")
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
        
        AssertRouteFound(router.lookup(uri: "/auth/register", method: .PUT), "/auth/register", .PUT)
        AssertRouteFound(router.lookup(uri: "/auth/login", method: .POST), "/auth/login", .POST)
        AssertRouteFound(router.lookup(uri: "/profile/123", method: .GET), "/profile/:id", .GET, ["id": "123"])
        AssertRouteFound(router.lookup(uri: "/profile/321/photo", method: .GET), "/profile/:id/photo", .GET, ["id": "321"])
        AssertRouteFound(router.lookup(uri: "/profile/9", method: .POST), "/profile/:id", .POST, ["id": "9"])
    }

    
    // MARK: -
    static var allTests = [
        ("testStaticRoutes", testStaticRoutes),
        ("testMethods", testMethods),
        ("testParams", testParams),
        ("testParamAllPath", testParamAllPath),
        ("testRouterErrors", testRouterErrors),
        ("testGroup", testGroup)
    ]
}
