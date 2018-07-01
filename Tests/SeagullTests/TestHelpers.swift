import Foundation
import NIOHTTP1
@testable import Seagull

extension PreparedRequest {
    static func testMake(uri: String = "", pattern: String = "", method: HTTPMethod = .GET, urlParams: StringDict = [:], queryParams: StringDict = [:], middleware: MiddlewareChain = [], handler: @escaping RequestHandler) -> PreparedRequest {
        return PreparedRequest(uri: uri, pattern: pattern, method: method, urlParams: urlParams, queryParams: queryParams, middleware: middleware, handler: handler)
    }
}

extension SgRequest {
    static func testMake(pattern: String = "", uri: String = "", method: HTTPMethod = .GET, headers: HTTPHeaders = HTTPHeaders(), urlParams: [String: String] = [:], queryParams: [String: String] = [:], body: Data? = nil) -> SgRequest {
        return SgRequest(pattern: pattern, uri: uri, method: method, headers: headers, urlParams: urlParams, queryParams: queryParams, body: body)
    }
}

func getResourcesPath(fileName: String, bundleClass: AnyClass) -> String {
    let path = FileManager.default.currentDirectoryPath + "/" + fileName
    #if os(Linux)
        return path
    #else
        if FileManager.default.fileExists(atPath: path) {
           return path
        }
    
        let bundlePath = Bundle(for: bundleClass).resourcePath!
        return bundlePath[bundlePath.startIndex..<bundlePath.range(of: "Seagull/")!.upperBound] + "/" + fileName
    #endif
}
