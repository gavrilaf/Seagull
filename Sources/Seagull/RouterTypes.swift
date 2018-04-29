import Foundation
import NIOHTTP1

struct SgError: Error {
    let code: HTTPResponseStatus
    let text: String
}


public typealias RequestHandler = (SgRequest, SgRequestContext) -> SgResult


