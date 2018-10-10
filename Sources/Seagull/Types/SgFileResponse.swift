import Foundation
import NIOHTTP1

public struct SgFileResponse {
    public let code: HTTPResponseStatus
    public let headers: HTTPHeaders
    public let path: String
    
    public init(path: String, headers: HTTPHeaders = Headers.MIME.octetStream, code: HTTPResponseStatus = .ok) {
        self.path = path
        self.headers = headers
        self.code = code
    }
}

