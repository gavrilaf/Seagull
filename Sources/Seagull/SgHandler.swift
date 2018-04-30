import Foundation
import NIOHTTP1
import Result

public struct SgError: Error {
    public let code: HTTPResponseStatus
    public let text: String
}

public typealias MiddlewareResult = Result<SgRequestContext, SgError>
public typealias MiddlewareHandler = (SgRequest, SgRequestContext) -> MiddlewareResult
public typealias MiddlewareChain = [MiddlewareHandler]

public typealias RequestHandler = (SgRequest, SgRequestContext) -> SgResult


