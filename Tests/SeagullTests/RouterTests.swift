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
    
}
