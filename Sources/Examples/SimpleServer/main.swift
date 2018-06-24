import Foundation
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
    
    try engine.run(host: "0.0.0.0", port: 8011)
    
    defer { try! engine.close() }
    try engine.waitForCompletion()
    
    print("I'm finished !!!")
    
} catch let err {
    print("Couldn't start server: \(err)")
}


