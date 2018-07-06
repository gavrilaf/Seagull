# Seagull

Swift web framework based on the swift-nio.

The Seagull main idea is creating a minimum web framework. Routing and some data processing helpers - nothing else. Seagull was inspired by gin-gonic, my favorite web framework for Golang. Lightweight, easy to use, minimum features set but really fast.

## Getting Started

Build & start test REST server.
```
swift build
./.build/debug/Rest
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
var router = Router()

try router.add(method: .POST, relativePath: "/register", handler: Handlers.register)    
try router.add(method: .POST, relativePath: "/logout", handler: Handlers.logout, middleware: [Handlers.tokenMiddleware])

let engine = Engine(router: router)
try engine.run(host: "::1", port: 8010)
    
defer { try! engine.close() }
try engine.waitForCompletion()
```

### Parameters in path

```swift
try router.add(method: .GET, relativePath: "/profile/shared/:username", handler: Handlers.getProfile)

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
try router.add(method: .GET, relativePath: "/withParams", handler: { (req, ctx) -> SgResult in
  let p1 = req.queryParams["paramOne"] ?? "not-found"
  let p2 = req.queryParams["paramTwo"] ?? "not-found"
  .....
}

.../withParams?paramOne=abc&paramTwo=100

```

### Grouping routes

```swift
try router.group("/auth/") {
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
try router.add(method: .GET, relativePath: "/site/*path", handler: siteContentHandler)
........

.../site/index.html
.../site/images/logo.jpg

```

**Project is in active development and isn't ready for production usage yet. But it's good for experiments :)**

Current version is 0.2.0

## TODO for the next release

* support for multipart/urlencoded form
* files uploading
* performance testing; comparing with Vapor, Perfect & gin-gonic

