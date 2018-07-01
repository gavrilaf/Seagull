import Seagull
import NIOHTTP1

let plainTextHandler: RequestHandler = { (_, ctx) in
    return SgResult.data(response: SgDataResponse.from(string: "This is just a string"))
}

let jsonObjHandler: RequestHandler = { (_, ctx) in
    struct TestObj: Encodable {
        let id: Int
        let name: String
        let status: Bool
    }
    
    return ctx.encode(json: TestObj(id: 1, name: "Test name", status: false))
}

let jsonDictHandler: RequestHandler = { (_, ctx) in
    let dict: [String: Any] = [
        "id": 123,
        "first_name": "Vasya",
        "info": ["locked": false, "scope": 12]
    ]
        
    return ctx.encode(dict: dict)
}

let fileHandler: RequestHandler = { (_, ctx) in
    let fileResp = SgFileResponse(path: "/Users/eugenf/Documents/Projects/Swift/my-github/HttpRouter/README.md")
    return SgResult.file(response: fileResp)
}


