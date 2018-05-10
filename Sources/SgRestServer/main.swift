import Seagull
import NIOHTTP1

let engine = Engine()

var router = Router()

let f1: RequestHandler = { (_, _) in
    return SgResult.data(response: SgDataResponse.from(string: "This is just a string"))
}

let f2: RequestHandler = { (_, _) in
    
    struct TestObj: Encodable {
        let id: Int
        let name: String
        let status: Bool
    }
    
    do {
        return SgResult.data(response: try SgDataResponse.from(json: TestObj(id: 1, name: "This is name", status: true)))
    } catch let err {
        return SgResult.error(response: SgErrorResponse.from(error: err))
    }
}

let f3: RequestHandler = { (_, _) in
    let dict: [String: Any] = [
        "id": 123,
        "first_name": "Vasya",
        "info": ["locked": false, "scope": 12]
    ]
    
    do {
        return SgResult.data(response: try SgDataResponse.from(dict: dict))
    } catch let err {
        return SgResult.error(response: SgErrorResponse.from(error: err))
    }
}

let f4: RequestHandler = { (_, _) in
    let fileResp = SgFileResponse.from(path: "/Users/eugenf/Documents/Projects/Swift/my-github/HttpRouter/README.md")
    return SgResult.file(response: fileResp)
}

try! router.add(method: .GET, relativePath: "/text", middleware: [], handler: f1)
try! router.add(method: .GET, relativePath: "/json-obj", middleware: [], handler: f2)
try! router.add(method: .GET, relativePath: "/json-dict", middleware: [], handler: f3)
try! router.add(method: .GET, relativePath: "/file", middleware: [], handler: f4)

engine.Run(router: router)
