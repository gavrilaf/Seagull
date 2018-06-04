# Seagull

Swift web framework based on the swift-nio.

Vapor, Perfect, Kitura are the well-known and good designed Swift web frameworks. Good designed with a lot of different features, but they are quite big ) 

The Seagull main idea is creating minimum web framework. Routing and some data processing helpers - nothing else. Seagull was inspired by gin-gonic, the my favourite web framework for Golang. Lightweight, easy to use, minimum featutures set but really fast.

## Getting Started

Just build & start test REST server.
```
swift build
./.build/debug/SgBaseRest
```
or using make
```
make run-rest 
```

Run intergation tests for base rest server implementation
```
make ptest
```

## Using Seagull

```swift
var router = Router()

try! router.group("/auth") {
  try $0.PUT("/register", handler: Handlers.register)
  try $0.POST("/login", handler: Handlers.login)
}
    
try! router.group("/profile", middleware: [Handlers.tokenMiddleware]) {
  try $0.GET("/", handler: Handlers.getMyProfile)
  try $0.POST("/", handler: Handlers.updateProfile)
  try $0.DELETE("/", handler: Handlers.deleteProfile)
}
    
try! router.add(method: .POST, relativePath: "/logout", handler: Handlers.logout, middleware: [Handlers.tokenMiddleware])

let engine = Engine(router: router)
try engine.run(host: "::1", port: 8010)
    
defer { try! engine.close() }
try engine.waitForCompletion()
```

** Project is in active development and isn't ready for production usage yet. But it's good for experiments :) **
