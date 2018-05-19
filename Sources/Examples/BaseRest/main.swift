import Seagull
import NIOHTTP1

do {
    print("Starting Seagull base REST server...")
    
    var router = Router()
    
    router.group(relativePath: <#T##String#>)
    
    let engine = Engine(router: router)
    try engine.run(host: "::1", port: 8010)
    
    defer { try! engine.close() }
    try engine.waitForCompletion()
    
} catch let err {
    print("Couldn't start server: \(err)")
}


