import Foundation
import Seagull
import NIOHTTP1

class WebServer {
    var router: Router
    var engine: Engine
    
    init() {
        let router = Router()
        
        self.router = router
        self.engine = Engine(router: router)
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
