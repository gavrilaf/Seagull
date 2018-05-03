import Seagull
import NIOHTTP1

let engine = Engine()

var router = Router()

let f1: RequestHandler = { (_, _) in
    return SgResult.from(string: "text-111")
}

let f2: RequestHandler = { (_, _) in
    return SgResult.from(string: "text-222")
}

let f3: RequestHandler = { (_, _) in
    return SgResult.from(string: "text-333")
}

let f4: RequestHandler = { (_, _) in
    let fileResp = SgFileResponse.from(path: "/Users/eugenf/Documents/Projects/Swift/my-github/HttpRouter/README.md")
    return SgResult.file(response: fileResp)
}

router.addHandler(forMethod: .GET, relativePath: "/text1", handler: f1, middleware: [])
router.addHandler(forMethod: .GET, relativePath: "/text2", handler: f2, middleware: [])
router.addHandler(forMethod: .GET, relativePath: "/text3", handler: f3, middleware: [])

router.addHandler(forMethod: .GET, relativePath: "/file-1", handler: f4, middleware: [])

engine.Run(router: router)
