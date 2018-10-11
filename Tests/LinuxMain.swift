import XCTest
@testable import SeagullTests

XCTMain([
    testCase(RouterTests.allTests),
    testCase(SgHandlerTests.allTests),
    testCase(EngineNIOTests.allTests),
    testCase(EngineIntegrationTests.allTests),
])
