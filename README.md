# Seagull

Swift web framework based on the swift-nio.

The Seagull main idea is creating a minimum web framework. Routing and some data processing helpers - nothing else. Seagull was inspired by gin-gonic, my favorite web framework for Golang. Lightweight, easy to use, minimum features set but really fast.

## News
Project updated to the version 0.2.5. The main feature is new, much more faster Router. 
https://github.com/gavrilaf/SgRouter

## Getting Started

Build & start test REST server.
```
swift run SeagullRestDemo
```
or using make
```
make run-rest 
```

Run integration tests for base rest server implementation
```
make ptest
```

## Run using docker-compose

Run unit tests 

```
docker-compose -f docker/docker-compose.yaml up unit-tests
```

Run Rest server example

```
docker-compose -f docker/docker-compose.yaml up rest
```

## API Examples

```swift
var router = HttpRouter()
try router.GET("/", handler: Handlers.ping)
try router.GET("whoami", handler: Handlers.whoami, with: [Handlers.tokenMiddleware])
    
let engine = Engine(router: router)
try engine.run(host: host, port: port)
    
defer { try! engine.close() }
try engine.waitForCompletion()
```

### Parameters in path

```swift
try router.GET("/profile/shared/:username", handler: Handlers.getProfile)

static func getProfile(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
  do {
    guard let username = request.urlParams["username"] else { throw AppLogicError.invalidParam }
    let profile = try Db.inst.getProfile(username: username)
    .....
  } catch let err {
    return ctx.error(err)
  }
}
```

### Querystring parameters

```swift
try router.GET("/withParams", handler: { (req, ctx) -> SgResult in
  let p1 = req.queryParams["paramOne"] ?? "not-found"
  let p2 = req.queryParams["paramTwo"] ?? "not-found"
  .....
}

.../withParams?paramOne=abc&paramTwo=100

```

### Grouping routes

```swift
try router.group("/auth") {
    try $0.PUT("/register", handler: Handlers.register)
    try $0.POST("/login", handler: Handlers.login)
}
```

### Using middleware

```swift
try router.group("/profile", middleware: [Handlers.tokenMiddleware, logMiddleware, ...]) {
  try $0.GET("/", handler: Handlers.getMyProfile)
  try $0.POST("/", handler: Handlers.updateProfile)
  try $0.DELETE("/", handler: Handlers.deleteProfile)
}
```

Middleware handlers will be called before the main handler in the order they are passed.

### Catch-all parameters

```swift
let siteContentHandler: RequestHandler = { (req, ctx) in
    let pathParam = req.urlParams["path"]!
    let path = FileManager.default.currentDirectoryPath + "/html/" + pathParam
    return SgResult.file(response: SgFileResponse(path: path, headers: mimeType))
}
........
try router.GET("/site/*path", handler: siteContentHandler)
........

.../site/index.html
.../site/images/logo.jpg

```

**Project is in active development and isn't ready for production usage yet. But it's good for experiments :)**

Current version is 0.2.5
