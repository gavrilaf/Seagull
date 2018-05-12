import Seagull
import NIOHTTP1

let engine = Engine()
var router = Router()

do {
    print("Starting Seagull test server...")
    
    try router.add(method: .GET, relativePath: "/text", handler: plainTextHandler)
    try router.add(method: .GET, relativePath: "/json-obj", handler: jsonObjHandler)
    try router.add(method: .GET, relativePath: "/json-dict", handler: jsonDictHandler)
    try router.add(method: .GET, relativePath: "/file", handler: fileHandler)
    
    engine.Run(router: router)
} catch let err {
    print("Couldn't start server: \(err)")
}


