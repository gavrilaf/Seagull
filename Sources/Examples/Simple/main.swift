import Foundation
import Seagull
import NIOHTTP1

var host = "::1"
var port = 8011

if CommandLine.arguments.count == 3 {
    host = CommandLine.arguments[1]
    port = Int(CommandLine.arguments[2]) ?? port
}

do {
    print("Starting Seagull test server...")
    
    var router = Router()
    
    try router.add(method: .GET, relativePath: "/text", handler: plainTextHandler)
    try router.add(method: .GET, relativePath: "/json-obj", handler: jsonObjHandler)
    try router.add(method: .GET, relativePath: "/json-dict", handler: jsonDictHandler)
    try router.add(method: .GET, relativePath: "/file", handler: fileHandler)
    
    try router.add(method: .GET, relativePath: "/site/", handler: siteRootHandler)
    try router.add(method: .GET, relativePath: "/site/*path", handler: siteContentHandler)
    
    let engine = Engine(router: router)
    
    try engine.run(host: host, port: port)
    
    defer { try! engine.close() }
    try engine.waitForCompletion()

} catch let err {
    print("Couldn't start server: \(err)")
}


