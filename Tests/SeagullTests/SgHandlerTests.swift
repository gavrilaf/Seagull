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
    
    func testSimpleHandler() {
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
    
}
