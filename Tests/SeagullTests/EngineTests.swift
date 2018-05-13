import XCTest
import NIO
import NIOHTTP1
@testable import Seagull

class EngineTests: XCTestCase {
    
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


    static var allTests = [
        ("testHelloWord", testHelloWord),
    ]
}
