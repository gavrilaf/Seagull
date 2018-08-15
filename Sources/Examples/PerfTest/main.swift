import Foundation
import Seagull
import NIO
import NIOHTTP1

// MARK: - Helpers

class HTTPClientResponsePartHandler: ArrayAccumulationHandler<HTTPClientResponsePart> {
    public init(_ expectedBody: String) {
        super.init { parts in
            guard parts.count >= 2 else {
                fatalError("only \(parts.count) parts")
            }
            
            var i = 1
            var bytes: [UInt8] = []
            while i < parts.count - 1 {
                if case .body(let bb) = parts[i] {
                    bb.withUnsafeReadableBytes { ptr in
                        bytes.append(contentsOf: ptr)
                    }
                } else {
                    fatalError("unexpected type on index \(i) \(parts[i])")
                }
                i += 1
            }
            
            let decoded = String(decoding: bytes, as: UTF8.self)
            if expectedBody != decoded {
                fatalError("Expected \(expectedBody), got \(decoded)")
            }
        }
    }
}

func runRequest(pool: MultiThreadedEventLoopGroup, address:SocketAddress, uri: String, expected: String, repeats: Int) {
    (0...repeats).forEach { _ in
        let accumulation = HTTPClientResponsePartHandler(expected)
        
        let clientChannel = try! ClientBootstrap(group: pool)
            .channelInitializer { channel in
                channel.pipeline.addHTTPClientHandlers().then {
                    channel.pipeline.add(handler: accumulation)
                }
            }
            .connect(to: address)
            .wait()
        
        defer {
            try! clientChannel.syncCloseAcceptingAlreadyClosed()
        }
        
        var head = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: .GET, uri: uri)
        head.headers.add(name: "Connection", value: "close")
    
        clientChannel.write(NIOAny(HTTPClientRequestPart.head(head)), promise: nil)
        try! clientChannel.writeAndFlush(NIOAny(HTTPClientRequestPart.end(nil))).wait()
    
        accumulation.syncWaitForCompletion()
    }
}

// MARK: - Server

class WebServer {
    var router: Router
    var engine: Engine
    
    init() {
        let router = Router()
        
        self.router = router
        self.engine = Engine(router: router, logger: EmptyLogger())
    }
    
    func run(port: Int) throws {
        try router.add(method: .GET, relativePath: "/simple", handler: { (_, _) -> SgResult in
            return SgResult.data(response: SgDataResponse.from(string: "simple"))
        })
        
        try router.add(method: .GET, relativePath: "/param/:name", handler: { (req, _) -> SgResult in
            return SgResult.data(response: SgDataResponse.from(string: "param: \(req.urlParams["name"] ?? "")"))
        })
        
        try router.add(method: .GET, relativePath: "/path/*path", handler: { (req, _) -> SgResult in
            return SgResult.data(response: SgDataResponse.from(string: "path: \(req.urlParams["path"] ?? "")"))
        })
        
        try router.add(method: .GET, relativePath: "/simple/query", handler: { (req, _) -> SgResult in
            return SgResult.data(response: SgDataResponse.from(string: "simple/query: \(req.queryParams["p"] ?? "")"))
        })
        
        try engine.run(host: "127.0.0.1", port: port)
    }
}

// MARK: - Start server

let server = WebServer()
try! server.run(port: 0)

// MARK: - Run measurements

let clientGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)

let iterations = 100

let startTime = CFAbsoluteTimeGetCurrent()

(0..<iterations).forEach { _ in
    runRequest(pool: clientGroup, address: server.engine.localAddress!, uri: "/simple", expected: "simple", repeats: 10)
    runRequest(pool: clientGroup, address: server.engine.localAddress!, uri: "/param/id1234", expected: "param: id1234", repeats: 10)
    runRequest(pool: clientGroup, address: server.engine.localAddress!, uri: "/path/script.js", expected: "path: script.js", repeats: 10)
    runRequest(pool: clientGroup, address: server.engine.localAddress!, uri: "/simple/query?p=id5678", expected: "simple/query: id5678", repeats: 10)
}

let totalTime = CFAbsoluteTimeGetCurrent() - startTime
let oneQueryTime = totalTime / Double(iterations * 40)

print("Average points: \(oneQueryTime * 1000)")





