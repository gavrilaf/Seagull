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
    }
    
    let engine = Engine(router: router)
    try engine.run(host: "::1", port: 8010)
    
    defer { try! engine.close() }
    try engine.waitForCompletion()
    
} catch let err {
    print("Couldn't start server: \(err)")
}


