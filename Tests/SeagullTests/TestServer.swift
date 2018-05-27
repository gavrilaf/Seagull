import Foundation
import Seagull

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
    var router: Router
    var engine: Engine
    
    init() {
        let router = Router()
        
        self.router = router
        self.engine = Engine(router: router)
    }
    
    func run(port: Int) throws {
        try router.add(method: .GET, relativePath: "/helloworld", handler: { (_, _) -> SgResult in
            return SgResult.data(response: SgDataResponse.from(string: "Hello world!"))
        })
        
        try router.add(method: .POST, relativePath: "/op", handler: { (req, ctx) -> SgResult in
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
