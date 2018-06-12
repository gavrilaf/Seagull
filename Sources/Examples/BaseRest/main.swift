import Seagull
import NIOHTTP1

do {
    print("Starting Seagull base REST server...")
    
    var router = Router()
    
    try! router.group("/auth") {
        try $0.PUT("/register", handler: Handlers.register)
        try $0.POST("/login", handler: Handlers.login)
    }
    
    try! router.group("/profile", middleware: [Handlers.tokenMiddleware]) {
        try $0.GET("/", handler: Handlers.getMyProfile)
        try $0.GET("/shared/:username", handler: Handlers.getProfile)
        try $0.POST("/", handler: Handlers.updateProfile)
        try $0.DELETE("/", handler: Handlers.deleteProfile)
    }
    
    try! router.add(method: .POST, relativePath: "/logout", handler: Handlers.logout, middleware: [Handlers.tokenMiddleware])
    try! router.add(method: .GET, relativePath: "/whoami", handler: Handlers.whoami, middleware: [Handlers.tokenMiddleware])
    
    let engine = Engine(router: router)
    try engine.run(host: "localhost", port: 8010)
    
    defer { try! engine.close() }
    try engine.waitForCompletion()
    
} catch let err {
    print("Couldn't start server: \(err)")
}


