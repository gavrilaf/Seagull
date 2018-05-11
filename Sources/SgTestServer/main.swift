import Seagull
import NIOHTTP1

let engine = Engine()
var router = Router()

do {
    print("Starting Seagull test server...")
    
    try router.add(method: .GET, relativePath: "/text", middleware: [], handler: plainTextHandler)
    try router.add(method: .GET, relativePath: "/json-obj", middleware: [], handler: jsonObjHandler)
    try router.add(method: .GET, relativePath: "/json-dict", middleware: [], handler: jsonDictHandler)
    try router.add(method: .GET, relativePath: "/file", middleware: [], handler: fileHandler)
    
    engine.Run(router: router)
} catch let err {
    print("Couldn't start server: \(err)")
}


