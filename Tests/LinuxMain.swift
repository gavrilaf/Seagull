import XCTest
@testable import SeagullTests

XCTMain([
    testCase(RouterTests.allTests),
    testCase(EngineTests.allTests),
])
