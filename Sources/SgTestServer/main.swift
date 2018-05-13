import Seagull
import NIOHTTP1

do {
    print("Starting Seagull test server...")
    
    var router = Router()
    
    try router.add(method: .GET, relativePath: "/text", handler: plainTextHandler)
    try router.add(method: .GET, relativePath: "/json-obj", handler: jsonObjHandler)
    try router.add(method: .GET, relativePath: "/json-dict", handler: jsonDictHandler)
    try router.add(method: .GET, relativePath: "/file", handler: fileHandler)
    
    let engine = Engine(router: router)
    
    try engine.run(host: "::1", port: 8010)
    
    defer { try! engine.close() }
    try engine.waitForCompletion()
    
} catch let err {
    print("Couldn't start server: \(err)")
}


