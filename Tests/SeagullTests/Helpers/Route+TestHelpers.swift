import Foundation
import NIOHTTP1
@testable import Seagull

let emptyRequestHandler: RequestHandler = { (_,_) in return SgResult.data(response: SgDataResponse.from(string: "")) }

extension ParsedRoute {
    static func testMake(pattern: String = "", uri: String = "", method: HTTPMethod = .GET, uriParams: [Substring: Substring] = [:], queryParams: [Substring: Substring] = [:]) -> ParsedRoute {
        return ParsedRoute(pattern: pattern, uri: uri, method: method, uriParams: uriParams, queryParams: queryParams)
    }
}

extension SgRequest {
    static func testMake(pattern: String = "", uri: String = "", method: HTTPMethod = .GET, headers: HTTPHeaders = HTTPHeaders(), uriParams: [Substring: Substring] = [:], queryParams: [Substring: Substring] = [:], body: Data? = nil) -> SgRequest {
        return SgRequest(route: ParsedRoute.testMake(pattern: pattern, uri: uri, method: method, uriParams: uriParams, queryParams: queryParams),
                         extra: RequestExtra(headers: headers, body: nil))
    }
}

extension RouteHandler {
    static func testMake(route: ParsedRoute = ParsedRoute.testMake(), handler: @escaping RequestHandler = emptyRequestHandler, middleware: MiddlewareChain = []) -> RouteHandler {
        return RouteHandler(parsedRoute: route, middleware: middleware, handler: handler)
    }
}
