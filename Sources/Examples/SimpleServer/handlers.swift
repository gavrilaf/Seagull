import Seagull
import NIOHTTP1

func logRequest(_ req: SgRequest) {
    print("Request: pattern=\(req.pattern), uri=\(req.uri), headers=\(req.headers)")
}

let plainTextHandler: RequestHandler = { (req, _) in
    logRequest(req)
    return SgResult.data(response: SgDataResponse.from(string: "This is just a string"))
}

let jsonObjHandler: RequestHandler = { (req, _) in
    logRequest(req)
    
    do {
        struct TestObj: Encodable {
            let id: Int
            let name: String
            let status: Bool
        }
        
        return SgResult.data(response: try SgDataResponse.from(json: TestObj(id: 1, name: "This is name", status: true)))
    } catch let err {
        return SgResult.error(response: SgErrorResponse.from(error: err))
    }
}

let jsonDictHandler: RequestHandler = { (req, _) in
    logRequest(req)
    
    do {
        let dict: [String: Any] = [
            "id": 123,
            "first_name": "Vasya",
            "info": ["locked": false, "scope": 12]
        ]
        
        return SgResult.data(response: try SgDataResponse.from(dict: dict))
    } catch let err {
        return SgResult.error(response: SgErrorResponse.from(error: err))
    }
}

let fileHandler: RequestHandler = { (req, _) in
    logRequest(req)
    
    let fileResp = SgFileResponse.from(path: "/Users/eugenf/Documents/Projects/Swift/my-github/HttpRouter/README.md")
    return SgResult.file(response: fileResp)
}


