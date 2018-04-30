import Seagull

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


router.addHandler(forMethod: .GET, relativePath: "/text1", handler: f1, middleware: [])
router.addHandler(forMethod: .GET, relativePath: "/text2", handler: f2, middleware: [])
router.addHandler(forMethod: .GET, relativePath: "/text3", handler: f3, middleware: [])

engine.Run(router: router)
