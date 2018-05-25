import Foundation
import Seagull

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
    
    func run(port: Int) throws {
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
        
        try engine.run(host: "127.0.0.1", port: port)
    }
}
