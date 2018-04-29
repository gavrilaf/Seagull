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


router.addHandler(forMethod: .GET, relativePath: "/text1", handlers: [f1])
router.addHandler(forMethod: .GET, relativePath: "/text2", handlers: [f2])
router.addHandler(forMethod: .GET, relativePath: "/text3", handlers: [f3])

engine.Run(router: router)
