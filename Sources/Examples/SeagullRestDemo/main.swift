import Seagull
import NIOHTTP1

var host = "::1"
var port = 8010

if CommandLine.arguments.count == 3 {
    host = CommandLine.arguments[1]
    port = Int(CommandLine.arguments[2]) ?? port
}

do {
    print("Starting Seagull base REST server...")
    
    var router = HttpRouter()
    
    try router.GET("/", handler: Handlers.ping)
    
    try router.group("/auth") {
        try $0.PUT("/register", handler: Handlers.register)
        try $0.POST("/login", handler: Handlers.login)
    }
    
    try router.group("/profile", middleware: [Handlers.tokenMiddleware]) {
        try $0.GET("/", handler: Handlers.getMyProfile)
        try $0.GET("/shared/:username", handler: Handlers.getProfile)
        try $0.POST("/", handler: Handlers.updateProfile)
        try $0.DELETE("/", handler: Handlers.deleteProfile)
    }
    
    try router.POST("logout", handler: Handlers.logout, with: [Handlers.tokenMiddleware])
    try router.GET("whoami", handler: Handlers.whoami, with: [Handlers.tokenMiddleware])
    
    let engine = Engine(router: router)
    try engine.run(host: host, port: port)
    
    defer { try! engine.close() }
    try engine.waitForCompletion()
    
} catch let err {
    print("Couldn't start server: \(err)")
}


