import Foundation
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
    let path = FileManager.default.currentDirectoryPath + "/README.md"
    let fileResp = SgFileResponse(path: path, headers: Headers.MIME.text)
    return SgResult.file(response: fileResp)
}


let siteRootHandler: RequestHandler = { (_, ctx) in
    let path = FileManager.default.currentDirectoryPath + "/html/index.html"
    let fileResp = SgFileResponse(path: path, headers: Headers.MIME.html)
    return SgResult.file(response: fileResp)
}

let siteContentHandler: RequestHandler = { (req, ctx) in
    let pathParam = req.urlParams["path"] ?? "not-found"
    
    let mimeType: HTTPHeaders!
    if pathParam == "index.html" {
        mimeType = Headers.MIME.html
    } else if pathParam.contains("images") {
        mimeType = Headers.MIME.jpg
    } else {
        mimeType = Headers.MIME.octetStream
    }
    
    let path = FileManager.default.currentDirectoryPath + "/html/" + pathParam
    let fileResp = SgFileResponse(path: path, headers: mimeType)
    return SgResult.file(response: fileResp)
}


