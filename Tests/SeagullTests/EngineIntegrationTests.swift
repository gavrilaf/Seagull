import XCTest
import Dispatch
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
        let exp = expectation(description: "wait for request")
        
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
        
        waitForExpectations(timeout: 1.0)
    }

    func testGetFile() {
        let exp = expectation(description: "wait for request")
        
        let task = URLSession.shared.dataTask(with: URL(string: "http://localhost:9876/file/README.md")!) { (data, resp, err) in
            let httpResp = resp as? HTTPURLResponse
            
            XCTAssertNil(err)
            XCTAssertEqual(200, httpResp?.statusCode)
            XCTAssertEqual("text/markdown", httpResp?.allHeaderFields["Content-Type"] as? String)
                        
            exp.fulfill()
        }
        
        task.resume()
        waitForExpectations(timeout: 1.0)
    }
    
    func testFileNotFound() {
        let exp = expectation(description: "wait for request")
        
        let task = URLSession.shared.dataTask(with: URL(string: "http://localhost:9876/file/README--.md")!) { (data, resp, err) in
            let httpResp = resp as? HTTPURLResponse
            
            XCTAssertNil(err)
            XCTAssertEqual(404, httpResp?.statusCode)
            exp.fulfill()
        }
        
        task.resume()
        waitForExpectations(timeout: 1.0)
    }
    
    func testJSON() {
        let exp = expectation(description: "wait for request")
        
        var req = URLRequest(url: URL(string: "http://localhost:9876/op")!)
        req.httpMethod = "POST"
        req.httpBody = try! JSONEncoder().encode(OpRequest(a: 120, b: 11, operation: "+"))
        
        let task = URLSession.shared.dataTask(with: req) { (data, resp, err) in
            let httpResp = resp as? HTTPURLResponse
            
            XCTAssertNil(err)
            XCTAssertEqual(200, httpResp?.statusCode)
            XCTAssertEqual("application/json", httpResp?.allHeaderFields["Content-Type"] as? String)
            XCTAssertEqual(OpResult(result: 131, operation: "+"), try! JSONDecoder().decode(OpResult.self, from: data!))
            
            exp.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: 1.0)
    }
        
    func testConnectionKeepAlive() {
        let exp = [expectation(description: "expectation 1"), expectation(description: "expectation 2"), expectation(description: "expectation 3")]
        
        func _send(indx: Int) {
            var req = URLRequest(url: URL(string: "http://localhost:9876/op")!)
            
            req.addValue("Connection", forHTTPHeaderField: "keep-alive")
            req.httpMethod = "POST"
            req.httpBody = try! JSONEncoder().encode(OpRequest(a: 120, b: 11, operation: "+"))
            
            let task = URLSession.shared.dataTask(with: req) { (data, resp, err) in
                let httpResp = resp as? HTTPURLResponse
                
                XCTAssertNil(err)
                XCTAssertEqual(200, httpResp?.statusCode)
                XCTAssertEqual("application/json", httpResp?.allHeaderFields["Content-Type"] as? String)
                
                XCTAssertEqual(OpResult(result: 131, operation: "+"), try! JSONDecoder().decode(OpResult.self, from: data!))
                
                exp[indx].fulfill()
            }
            
            task.resume()
        }
        
        DispatchQueue.global().async {
            _send(indx: 0)
        }
        
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(100)) {
            _send(indx: 1)
        }
        
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(200)) {
            _send(indx: 2)
        }
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testConcurrentCalls() {
        let exp = (0..<50).map { return self.expectation(description: "expectation \($0)") }
        
        func _send(indx: Int, keepAlive: Bool, lhs: Int, rhs: Int) {
            var req = URLRequest(url: URL(string: "http://localhost:9876/op")!)
            
            if keepAlive { req.addValue("Connection", forHTTPHeaderField: "keep-alive") }
            req.httpMethod = "POST"
            req.httpBody = try! JSONEncoder().encode(OpRequest(a: lhs, b: rhs, operation: "+"))
            
            let task = URLSession.shared.dataTask(with: req) { (data, resp, err) in
                let httpResp = resp as? HTTPURLResponse
                
                XCTAssertNil(err)
                XCTAssertEqual(200, httpResp?.statusCode)
                XCTAssertEqual("application/json", httpResp?.allHeaderFields["Content-Type"] as? String)
                
                XCTAssertEqual(OpResult(result: lhs + rhs, operation: "+"), try! JSONDecoder().decode(OpResult.self, from: data!))
                
                exp[indx].fulfill()
            }
            
            task.resume()
        }
        
        let queue = DispatchQueue(label: "", qos: .default, attributes: .concurrent)
        for indx in 0..<50 {
            queue.async {
                _send(indx: indx, keepAlive: indx % 2 == 0, lhs: indx + 1, rhs: indx*2)
            }
        }
        
        waitForExpectations(timeout: 3.0)
    }
    
    // MARK: -
    static var allTests = [
        ("testHelloWord", testHelloWord),
        ("testGetFile", testGetFile),
        ("testFileNotFound", testFileNotFound),
        ("testJSON", testJSON),
        ("testConnectionKeepAlive", testConnectionKeepAlive),
        ("testConcurrentCalls", testConcurrentCalls),
    ]
}
