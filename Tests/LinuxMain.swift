import XCTest
@testable import SeagullTests

XCTMain([
    testCase(PathBuilderTests.allTests),
    testCase(SgHandlerTests.allTests),
    testCase(RouterTests.allTests),
    testCase(EngineNIOTests.allTests),
    testCase(EngineIntegrationTests.allTests),
])
