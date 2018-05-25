import XCTest
import Seagull

class EngineIntegrationTests: XCTestCase {
    
    var server: TestWebServer!
    
    override func setUp() {
        super.setUp()
        
        self.server = TestWebServer()
        XCTAssertNoThrow(try self.server.run(port: 9876))
    }
    
    override func tearDown() {
        try! server.engine.close()
        super.tearDown()
    }
    
    func testHelloWord() {
        let exp = XCTestExpectation()
        
        let task = URLSession.shared.dataTask(with: URL(string: "http://localhost:9876/helloword")!) { (data, resp, err) in
            let httpResp = resp as? HTTPURLResponse
            
            XCTAssertNil(err)
            XCTAssertEqual(200, httpResp?.statusCode)
            
            exp.fulfill()
        }
        
        task.resume()
        
        wait(for: [exp], timeout: 1.0)
    }
}
