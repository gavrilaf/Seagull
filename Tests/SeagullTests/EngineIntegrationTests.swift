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
        
        let task = URLSession.shared.dataTask(with: URL(string: "http://localhost:9876/helloworld")!) { (data, resp, err) in
            let httpResp = resp as? HTTPURLResponse
            
            XCTAssertNil(err)
            XCTAssertEqual(200, httpResp?.statusCode)
            XCTAssertEqual("text/plain", httpResp?.allHeaderFields["Content-Type"] as? String)
            
            let str = String(data: data!, encoding: .utf8)
            XCTAssertEqual("Hello world!", str)
            
            exp.fulfill()
        }
        
        task.resume()
        wait(for: [exp], timeout: 1.0)
    }
    
    func testJSON() {
        let exp = XCTestExpectation()
        
        var req = URLRequest(url: URL(string: "http://localhost:9876/op")!)
        req.httpMethod = "POST"
        req.httpBody = try! JSONEncoder().encode(OpRequest(a: 120, b: 11, operation: "+"))
        
        let task = URLSession.shared.dataTask(with: req) { (data, resp, err) in
            let httpResp = resp as? HTTPURLResponse
            
            XCTAssertNil(err)
            XCTAssertEqual(200, httpResp?.statusCode)
            XCTAssertEqual("application/json", httpResp?.allHeaderFields["Content-Type"] as? String)
            
            exp.fulfill()
        }
        
        task.resume()
        wait(for: [exp], timeout: 1.0)
    }
}
