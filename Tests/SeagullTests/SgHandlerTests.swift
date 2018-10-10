import XCTest
import NIOHTTP1
@testable import Seagull

class SgHandlerTests: XCTestCase {
    
    var context: SgRequestContext!
    
    override func setUp() {
        super.setUp()
        context = SgRequestContext(logger: DefaultLogger(), errorProvider: DefaultErrorProvider())
    }
    
    func testHandlerNoMiddleware() {
        let handler: RequestHandler = { (_, context) -> SgResult in return SgResult.data(response: SgDataResponse.from(string: "test")) }
        let subject = RouteHandler.testMake(handler: handler)
        
        let result = subject.handle(request: SgRequest.testMake(), with: context)
        
        AssertRouterSgResult(result, "test")
    }
    
    func testMiddlewareChain() {
        let midl1: MiddlewareHandler = { (_, ctx) -> MiddlewareResult in
            var mutableContext = ctx
            mutableContext.set(value: "12345", forKey: "token")
            return MiddlewareResult(value: mutableContext)
        }
        
        let midl2: MiddlewareHandler = { (_, ctx) -> MiddlewareResult in
            var mutableContext = ctx
            mutableContext.set(value: "test", forKey: "user")
            return MiddlewareResult(value: mutableContext)
        }
        
        let handler: RequestHandler = { (_, context) -> SgResult in
            let token = context.userInfo["token"] as! String
            let user = context.userInfo["user"] as! String
            return SgResult.data(response: SgDataResponse.from(string: "token=\(token);user=\(user)"))
        }
        
        let subject = RouteHandler.testMake(handler: handler, middleware: [midl1, midl2])
        let result = subject.handle(request: SgRequest.testMake(), with: context)
        
        AssertRouterSgResult(result, "token=12345;user=test")
    }
    
    func testMiddlewareWithError() {
        enum TestError: Error, Equatable {
            case testErr
        }
        
        let midl1: MiddlewareHandler = { (_, ctx) -> MiddlewareResult in
            var mutableContext = ctx
            mutableContext.set(value: "12345", forKey: "token")
            return MiddlewareResult(value: mutableContext)
        }
        
        let midl2: MiddlewareHandler = { (_, ctx) -> MiddlewareResult in
            return MiddlewareResult(error: SgErrorResponse.make(string: "test-error", code: .badRequest, err: TestError.testErr))
        }
        
        let subject = RouteHandler.testMake(handler: emptyRequestHandler, middleware: [midl1, midl2])
        let result = subject.handle(request: SgRequest.testMake(), with: context)
        
        AssertRouterSgResult(result, "test-error", HTTPResponseStatus.badRequest)
    }
    
    // MARK: -
    static var allTests = [
        ("testHandlerNoMiddleware", testHandlerNoMiddleware),
        ("testMiddlewareChain", testMiddlewareChain),
        ("testMiddlewareWithError", testMiddlewareWithError)
    ]
}
