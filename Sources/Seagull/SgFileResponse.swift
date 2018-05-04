import Foundation
import NIOHTTP1

public struct SgFileResponse {
    public let code: HTTPResponseStatus
    public let headers: HTTPHeaders
    public let path: String
}

extension SgFileResponse {
    public static func from(path: String) -> SgFileResponse {
        return SgFileResponse(code: .ok, headers: HTTPHeaders(), path: path)
    }
}
