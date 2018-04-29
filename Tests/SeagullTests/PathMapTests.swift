import XCTest
@testable import Seagull

class PathMapTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSimplePath() {
        let map = PathMap<Int>()
        let pathes = ["/", "/test-1", "/test-2", "/test-2/test-3"]
        
        for (indx, p) in pathes.enumerated() {
            map.add(path: p, indx + 1)
        }
        
        for (indx, p) in pathes.enumerated() {
            let found = map.get(path: p)
            XCTAssertNotNil(found)
            XCTAssertEqual(indx + 1, found?.value)
            XCTAssertEqual(true, found?.pathParams.isEmpty)
            XCTAssertEqual(true, found?.queryParams.isEmpty)
        }
        
        XCTAssertNil(map.get(path: "/not-found"))
    }
    
    static var allTests = [
        ("testSimplePath", testSimplePath),
    ]
}
