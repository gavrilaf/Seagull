import XCTest
@testable import SeagullTests

XCTMain([
    testCase(UriParserTests.allTests),
    testCase(RouterTests.allTests),
    testCase(SgHandlerTests.allTests),
    testCase(EngineNIOTests.allTests),
    testCase(EngineIntegrationTests.allTests),
])
