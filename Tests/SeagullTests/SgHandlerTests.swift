import XCTest
import NIOHTTP1
@testable import Seagull

class SgHandlerTests: XCTestCase {
    
    var context: SgRequestContext!
    
    override func setUp() {
        super.setUp()
        
        context = SgRequestContext(logger: DefaultLogger(), errorProvider: DefaultErrorProvider())
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testHandlerNoMiddleware() {
        let subject = PreparedRequest.testMake { (_, context) -> SgResult in
            return SgResult.data(response: SgDataResponse.from(string: "test"))
        }
        
        let result = subject.handle(request: SgRequest.testMake(), ctx: context)
        
        XCTAssertEqual(HTTPResponseStatus.ok, result.httpCode)
        if case .data(let resp) = result {
            XCTAssertEqual("test", String(data: resp.body!, encoding: .utf8))
        } else {
            XCTFail()
        }
    }
    
    func testMiddlewareChain() {
        let chain: MiddlewareChain = [
            { (_, ctx) -> MiddlewareResult in
                var mutableContext = ctx
                mutableContext.set(value: "12345", forKey: "token")
                return MiddlewareResult(value: mutableContext)
            },
            { (_, ctx) -> MiddlewareResult in
                var mutableContext = ctx
                mutableContext.set(value: "test", forKey: "user")
                return MiddlewareResult(value: mutableContext)
            },
        ]
        
        let subject = PreparedRequest.testMake(middleware: chain) { (_, context) -> SgResult in
            let token = context.userInfo["token"] as! String
            let user = context.userInfo["user"] as! String
            return SgResult.data(response: SgDataResponse.from(string: "token=\(token);user=\(user)"))
        }
        
        let result = subject.handle(request: SgRequest.testMake(), ctx: context)
        
        XCTAssertEqual(HTTPResponseStatus.ok, result.httpCode)
        if case .data(let resp) = result {
            XCTAssertEqual("token=12345;user=test", String(data: resp.body!, encoding: .utf8))
        } else {
            XCTFail()
        }
    }
    
    func testMiddlewareWithError() {
        
        enum TestError: Error, Equatable {
            case testErr
        }
        
        let chain: MiddlewareChain = [
            { (_, ctx) -> MiddlewareResult in
                var mutableContext = ctx
                mutableContext.set(value: "12345", forKey: "token")
                return MiddlewareResult(value: mutableContext)
                },
            { (_, ctx) -> MiddlewareResult in
                return MiddlewareResult(error: SgErrorResponse.make(string: "test-error", code: .badRequest, err: TestError.testErr))
            }
        ]
        
        let subject = PreparedRequest.testMake(middleware: chain) { (_, context) -> SgResult in
            return SgResult.data(response: SgDataResponse.from(string: "test"))
        }
        
        let result = subject.handle(request: SgRequest.testMake(), ctx: context)
        
        XCTAssertEqual(HTTPResponseStatus.badRequest, result.httpCode)
        if case .error(let resp) = result {
            XCTAssertEqual(TestError.testErr, resp.error as? TestError)
            XCTAssertEqual("test-error", String(data: resp.response.body!, encoding: .utf8))
        } else {
            XCTFail()
        }
    }
    
    // MARK: -
    static var allTests = [
        ("testHandlerNoMiddleware", testHandlerNoMiddleware),
        ("testMiddlewareChain", testMiddlewareChain),
        ("testMiddlewareWithError", testMiddlewareWithError)
    ]
}
