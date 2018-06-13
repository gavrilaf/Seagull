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
            try! XCTAssertEqual(OpResult(result: 131, operation: "+"), try JSONDecoder().decode(OpResult.self, from: data!))
            
            exp.fulfill()
        }
        
        task.resume()
        wait(for: [exp], timeout: 1.0)
    }
        
    func testConnectionKeepAlive() {
        let exp = XCTestExpectation()
        
        func _send() {
            var req = URLRequest(url: URL(string: "http://localhost:9876/op")!)
            
            req.addValue("Connection", forHTTPHeaderField: "keep-alive")
            req.httpMethod = "POST"
            req.httpBody = try! JSONEncoder().encode(OpRequest(a: 120, b: 11, operation: "+"))
            
            let task = URLSession.shared.dataTask(with: req) { (data, resp, err) in
                let httpResp = resp as? HTTPURLResponse
                
                XCTAssertNil(err)
                XCTAssertEqual(200, httpResp?.statusCode)
                XCTAssertEqual("application/json", httpResp?.allHeaderFields["Content-Type"] as? String)
                
                try! XCTAssertEqual(OpResult(result: 131, operation: "+"), try JSONDecoder().decode(OpResult.self, from: data!))
                
                exp.fulfill()
            }
            
            task.resume()
        }
        
        exp.expectedFulfillmentCount = 3
        
        DispatchQueue.global().async {
            _send()
        }
        
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(100)) {
            _send()
        }
        
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(200)) {
            _send()
        }
        
        
        wait(for: [exp], timeout: 3.0)
    }
    
    func testConcurrentCalls() {
        let exp = XCTestExpectation()
        
        func _send(keepAlive: Bool, lhs: Int, rhs: Int) {
            var req = URLRequest(url: URL(string: "http://localhost:9876/op")!)
            
            if keepAlive { req.addValue("Connection", forHTTPHeaderField: "keep-alive") }
            req.httpMethod = "POST"
            req.httpBody = try! JSONEncoder().encode(OpRequest(a: lhs, b: rhs, operation: "+"))
            
            let task = URLSession.shared.dataTask(with: req) { (data, resp, err) in
                let httpResp = resp as? HTTPURLResponse
                
                XCTAssertNil(err)
                XCTAssertEqual(200, httpResp?.statusCode)
                XCTAssertEqual("application/json", httpResp?.allHeaderFields["Content-Type"] as? String)
                
                try! XCTAssertEqual(OpResult(result: lhs + rhs, operation: "+"), try JSONDecoder().decode(OpResult.self, from: data!))
                
                exp.fulfill()
            }
            
            task.resume()
        }
        
        let attempts = 50
        let queue = DispatchQueue(label: "", qos: .default, attributes: .concurrent)
        
        exp.expectedFulfillmentCount = attempts
        
        for indx in 0..<50 {
            queue.async {
                _send(keepAlive: indx % 2 == 0, lhs: indx + 1, rhs: indx*2)
            }
        }
        
        wait(for: [exp], timeout: 3.0)
    }
    
    // MARK: -
    static var allTests = [
        ("testHelloWord", testHelloWord),
        ("testJSON", testJSON),
        ("testConnectionKeepAlive", testConnectionKeepAlive),
        ("testConcurrentCalls", testConcurrentCalls),
    ]

}
