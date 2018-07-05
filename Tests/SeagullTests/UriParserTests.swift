import XCTest
import NIOHTTP1
@testable import Seagull

class UriParserTests: XCTestCase {
    
    func testPathes() {
        XCTAssertEqual([], UriParser(uri: "/").pathComponents)
        XCTAssertEqual([], UriParser(uri: "/////").pathComponents)
        XCTAssertEqual(["user"], UriParser(uri: "/user").pathComponents)
        XCTAssertEqual(["user"], UriParser(uri: "/user/").pathComponents)
        XCTAssertEqual(["user"], UriParser(uri: "//user//").pathComponents)
        XCTAssertEqual(["user", "profile"], UriParser(uri: "/user/profile").pathComponents)
        XCTAssertEqual(["user", "profile", ":id"], UriParser(uri: "/user/profile/:id").pathComponents)
        XCTAssertEqual(["user", "profile", "*action"], UriParser(uri: "/user/profile/*action").pathComponents)
        XCTAssertEqual(["user", "profile", ":id", "*action"], UriParser(uri: "/user/profile/:id/*action").pathComponents)
    }

    static var allTests = [
        ("testPathes", testPathes),
    ]
}
