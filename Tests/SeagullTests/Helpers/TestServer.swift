import Foundation
import Seagull
import NIOHTTP1

struct OpRequest: Codable {
    let a: Int
    let b: Int
    let operation: String
}

struct OpResult: Codable, Equatable {
    let result: Int
    let operation: String
}

class TestWebServer {
    var router: HttpRouter
    var engine: Engine
    
    init() {
        let router = HttpRouter()
        
        self.router = router
        self.engine = Engine(router: router)
    }
    
    func run(port: Int) throws {
        try router.GET("/helloworld", handler: { (_, _) -> SgResult in
            return SgResult.data(response: SgDataResponse.from(string: "Hello world!"))
        })

        try router.GET("/file/:file", handler: { (req, ctx) -> SgResult in
            let fileName = req.route.uriParams["file"] ?? "unknown_file"
            let path = getResourcesPath(filePath: String(fileName), bundleClass: type(of: self))
            return SgResult.file(response: SgFileResponse(path: path, headers: HTTPHeaders([("Content-Type", "text/markdown")])))
        })
        
        try router.GET("/site/*path", handler: { (req, ctx) -> SgResult in
            let pathParam = "html/" + (req.route.uriParams["path"] ?? "not-found")
            
            let mimeType: HTTPHeaders!
            if pathParam.contains("index.html") {
                mimeType = Headers.MIME.html
            } else if pathParam.contains("images") {
                mimeType = Headers.MIME.jpg
            } else {
                mimeType = Headers.MIME.octetStream
            }
            
            let path = getResourcesPath(filePath: String(pathParam), bundleClass: type(of: self))
            let fileResp = SgFileResponse(path: path, headers: mimeType)
            return SgResult.file(response: fileResp)
        })
        
        try router.GET("/withParams", handler: { (req, ctx) -> SgResult in
            let p1 = req.route.queryParams["p1"] ?? "not-found"
            let p2 = req.route.queryParams["p2"] ?? "not-found"
            let p3 = req.route.queryParams["p3"] ?? "not-found"
            
            return SgResult.data(response: SgDataResponse.from(string: "p1=\(p1) p2=\(p2) p3=\(p3)"))
        })
        
        try router.POST("/op", handler: { (req, ctx) -> SgResult in
            do {
                let op = try ctx.decode(OpRequest.self, request: req)
                
                if op.operation == "+" {
                    return ctx.encode(json: OpResult(result: op.a + op.b, operation: "+"))
                } else {
                    return SgResult.error(response: SgErrorResponse.make(string: "Unknown operation", code: .notImplemented))
                }
            } catch let err {
                return SgResult.error(response: ctx.errorProvider.generalError(err))
            }
        })
        
        try engine.run(host: "127.0.0.1", port: port)
    }
}
