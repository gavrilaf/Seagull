import Seagull
import NIOHTTP1

func logRequest(_ req: SgRequest, _ ctx: SgRequestContext) {
    ctx.logger.info("Request: pattern=\(req.pattern), uri=\(req.uri), headers=\(req.headers)")
}

let plainTextHandler: RequestHandler = { (req, ctx) in
    logRequest(req, ctx)
    return SgResult.data(response: SgDataResponse.from(string: "This is just a string"))
}

let jsonObjHandler: RequestHandler = { (req, ctx) in
    logRequest(req, ctx)
    
    struct TestObj: Encodable {
        let id: Int
        let name: String
        let status: Bool
    }
    
    return ctx.encode(json: TestObj(id: 1, name: "Test name", status: false))
}

let jsonDictHandler: RequestHandler = { (req, ctx) in
    logRequest(req, ctx)
    
    let dict: [String: Any] = [
        "id": 123,
        "first_name": "Vasya",
        "info": ["locked": false, "scope": 12]
    ]
        
    return ctx.encode(dict: dict)
}

let fileHandler: RequestHandler = { (req, ctx) in
    logRequest(req, ctx)
    
    let fileResp = SgFileResponse.from(path: "/Users/eugenf/Documents/Projects/Swift/my-github/HttpRouter/README.md")
    return SgResult.file(response: fileResp)
}


