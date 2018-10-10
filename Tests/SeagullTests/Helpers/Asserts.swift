import Foundation
import Result
import NIOHTTP1
import XCTest
import Seagull

func AssertRouteFound(_ res: Result<RouteHandler, RouterError>, _ pattern: String, _ method: HTTPMethod, _ uriP: [Substring: Substring] = [:], _ queryP: [Substring: Substring] = [:], file: StaticString = #file, line: UInt = #line) {
    switch res {
    case .success(let handler):
        let route = handler.parsedRoute
        XCTAssertEqual(pattern, route.pattern, file: file, line: line)
        XCTAssertEqual(method, route.method, file: file, line: line)
        XCTAssertEqual(uriP, route.uriParams, file: file, line: line)
        XCTAssertEqual(queryP, route.queryParams, file: file, line: line)
    case .failure(let err):
        XCTAssertFalse(true, "check route failed: \(method.str) : \(pattern), \(err)", file: file, line: line)
    }
}

func AssertAddRouteError(_ router: HttpRouter, _ path: String, file: StaticString = #file, line: UInt = #line) {
    XCTAssertThrowsError(try router.GET(path, handler: emptyRequestHandler), file: file, line: line) { (err) in
        switch err {
        case RouterError.invalidPath(let errPath):
            XCTAssertEqual(path, errPath, file: file, line: line)
        default:
            XCTAssertTrue(false, "invalid router error", file: file, line: line)
        }
    }
}

func AssertRouterSgResult(_ res: SgResult, _ body: String, _ code: HTTPResponseStatus = HTTPResponseStatus.ok, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(code, res.httpCode, file: file, line: line)
    
    if res.httpCode == HTTPResponseStatus.ok {
        if case .data(let resp) = res {
            XCTAssertEqual(body.data(using: .utf8), resp.body, file: file, line: line)
        } else {
            XCTFail("RouterResult has invalid type, should be data", file: file, line: line)
        }
    } else { // error
        if case .error(let resp) = res {
            XCTAssertEqual(body.data(using: .utf8), resp.response.body, file: file, line: line)
        } else {
            XCTFail("RouterResult has invalid type, should be error", file: file, line: line)
        }
    }
}
