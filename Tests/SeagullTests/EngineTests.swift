import XCTest
import NIO
import NIOHTTP1
@testable import Seagull

class EngineTests: XCTestCase {
    
    struct OpRequest: Codable {
        let a: Int
        let b: Int
        let operation: String
    }

    struct OpResult: Codable {
        let result: Int
        let operation: String
    }

    class TestWebServer {
        var router: Router
        var engine: Engine
        
        init() {
            let router = Router()
            
            self.router = router
            self.engine = Engine(router: router)
        }
        
        func run() throws {
            try router.add(method: .GET, relativePath: "/helloworld", handler: { (_, _) -> SgResult in
                return SgResult.data(response: SgDataResponse.from(string: "Hello world!"))
            })
            
            try router.add(method: .POST, relativePath: "/op", handler: { (req, _) -> SgResult in
                let decoder = JSONDecoder()
                let op = try! decoder.decode(OpRequest.self, from: req.body!)
                
                switch op.operation {
                case "+":
                    return SgResult.data(response: try! SgDataResponse.from(json: OpResult(result: 10, operation: "+")))
                default:
                    return SgResult.error(response: SgErrorResponse.appError(string: "Unknown operation", code: .notImplemented))
                }
            })
            
            try engine.run(host: "127.0.0.1", port: 0)
        }
    }
    
    var server: TestWebServer!
    var clientGroup: MultiThreadedEventLoopGroup!
    
    override func setUp() {
        self.server = TestWebServer()
        XCTAssertNoThrow(try self.server.run())
        
        self.clientGroup = MultiThreadedEventLoopGroup(numThreads: 1)
    }
    
    override func tearDown() {
        try! server.engine.close()
    }
    
    func testHelloWord() {
        var expectedHeaders = HTTPHeaders()
        expectedHeaders.add(name: "Connection", value: "close")
        expectedHeaders.add(name: "Content-Length", value: "12")
        expectedHeaders.add(name: "Content-Type", value: "text/plain")
        
        let accumulation = HTTPClientResponsePartAssertHandler(HTTPVersion(major: 1, minor: 1), .ok, expectedHeaders, "Hello world!")
        
        let clientChannel = try! ClientBootstrap(group: self.clientGroup)
            .channelInitializer { channel in
                channel.pipeline.addHTTPClientHandlers().then {
                    channel.pipeline.add(handler: accumulation)
                }
            }
            .connect(to: self.server.engine.localAddress!)
            .wait()
        
        defer {
            XCTAssertNoThrow(try clientChannel.syncCloseAcceptingAlreadyClosed())
        }
        
        var head = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: .GET, uri: "/helloworld")
        head.headers.add(name: "Connection", value: "close")
        
        clientChannel.write(NIOAny(HTTPClientRequestPart.head(head)), promise: nil)
        try! clientChannel.writeAndFlush(NIOAny(HTTPClientRequestPart.end(nil))).wait()
        
        accumulation.syncWaitForCompletion()
    }
    
    func testSuccessOperation() {
        var expectedHeaders = HTTPHeaders()
        expectedHeaders.add(name: "Connection", value: "close")
        expectedHeaders.add(name: "Content-Length", value: "29")
        expectedHeaders.add(name: "Content-Type", value: "application/json")
        
        let jsonStr = "{\"result\":10,\"operation\":\"+\"}"
        let accumulation = HTTPClientResponsePartAssertHandler(HTTPVersion(major: 1, minor: 1), .ok, expectedHeaders, jsonStr)
        
        let clientChannel = try! ClientBootstrap(group: self.clientGroup)
            .channelInitializer { channel in
                channel.pipeline.addHTTPClientHandlers().then {
                    channel.pipeline.add(handler: accumulation)
                }
            }
            .connect(to: self.server.engine.localAddress!)
            .wait()
        
        defer {
            XCTAssertNoThrow(try clientChannel.syncCloseAcceptingAlreadyClosed())
        }
        
        var head = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: .POST, uri: "/op")
        head.headers.add(name: "Connection", value: "close")
        
        clientChannel.write(NIOAny(HTTPClientRequestPart.head(head)), promise: nil)
        
        let encoder = JSONEncoder()
        let opObj = OpRequest(a: 2, b: 3, operation: "+")
        let data = try! encoder.encode(opObj)
        
        var buffer = clientChannel.allocator.buffer(capacity: data.count)
        buffer.write(bytes: data)
        
        clientChannel.write(NIOAny(HTTPClientRequestPart.body(IOData.byteBuffer(buffer))), promise: nil)
        try! clientChannel.writeAndFlush(NIOAny(HTTPClientRequestPart.end(nil))).wait()
        
        accumulation.syncWaitForCompletion()
    }
    
    func testUnknownOperation() {
        var expectedHeaders = HTTPHeaders()
        expectedHeaders.add(name: "Connection", value: "close")
        expectedHeaders.add(name: "Content-Length", value: "17")
        expectedHeaders.add(name: "Content-Type", value: "text/plain")
        
        let accumulation = HTTPClientResponsePartAssertHandler(HTTPVersion(major: 1, minor: 1), .notImplemented, expectedHeaders, "Unknown operation")
        
        let clientChannel = try! ClientBootstrap(group: self.clientGroup)
            .channelInitializer { channel in
                channel.pipeline.addHTTPClientHandlers().then {
                    channel.pipeline.add(handler: accumulation)
                }
            }
            .connect(to: self.server.engine.localAddress!)
            .wait()
        
        defer {
            XCTAssertNoThrow(try clientChannel.syncCloseAcceptingAlreadyClosed())
        }
        
        var head = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: .POST, uri: "/op")
        head.headers.add(name: "Connection", value: "close")
        
        clientChannel.write(NIOAny(HTTPClientRequestPart.head(head)), promise: nil)
        
        let encoder = JSONEncoder()
        let opObj = OpRequest(a: 2, b: 3, operation: "//")
        let data = try! encoder.encode(opObj)
        
        var buffer = clientChannel.allocator.buffer(capacity: data.count)
        buffer.write(bytes: data)
        
        clientChannel.write(NIOAny(HTTPClientRequestPart.body(IOData.byteBuffer(buffer))), promise: nil)
        try! clientChannel.writeAndFlush(NIOAny(HTTPClientRequestPart.end(nil))).wait()
        
        accumulation.syncWaitForCompletion()
    }

    func test404() {
        var expectedHeaders = HTTPHeaders()
        expectedHeaders.add(name: "Connection", value: "close")
        expectedHeaders.add(name: "Content-Length", value: "30")
        expectedHeaders.add(name: "Content-Type", value: "text/plain")
        
        let accumulation = HTTPClientResponsePartAssertHandler(HTTPVersion(major: 1, minor: 1), .notFound, expectedHeaders, "Handler for GET /404 not found")
        
        let clientChannel = try! ClientBootstrap(group: self.clientGroup)
            .channelInitializer { channel in
                channel.pipeline.addHTTPClientHandlers().then {
                    channel.pipeline.add(handler: accumulation)
                }
            }
            .connect(to: self.server.engine.localAddress!)
            .wait()
        
        defer {
            XCTAssertNoThrow(try clientChannel.syncCloseAcceptingAlreadyClosed())
        }
        
        var head = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: .GET, uri: "/404")
        head.headers.add(name: "Connection", value: "close")
        
        clientChannel.write(NIOAny(HTTPClientRequestPart.head(head)), promise: nil)
        try! clientChannel.writeAndFlush(NIOAny(HTTPClientRequestPart.end(nil))).wait()
        
        accumulation.syncWaitForCompletion()
    }


    static var allTests = [
        ("testHelloWord", testHelloWord),
        ("testSuccessOperation", testSuccessOperation)
    ]
}
