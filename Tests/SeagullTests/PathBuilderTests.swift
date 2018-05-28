import XCTest
import NIOHTTP1
@testable import Seagull

class PathBuilderTests: XCTestCase {
    
    func testPathes() {
        XCTAssertEqual(["GET"], PathBuilder(method: .GET, uri: "/").pathComponents)
        XCTAssertEqual(["GET"], PathBuilder(method: .GET, uri: "/////").pathComponents)
        XCTAssertEqual(["user", "GET"], PathBuilder(method: .GET, uri: "/user").pathComponents)
        XCTAssertEqual(["user", "GET"], PathBuilder(method: .GET, uri: "/user/").pathComponents)
        XCTAssertEqual(["user", "GET"], PathBuilder(method: .GET, uri: "//user//").pathComponents)
        XCTAssertEqual(["user", "profile", "GET"], PathBuilder(method: .GET, uri: "/user/profile").pathComponents)
    }
}
