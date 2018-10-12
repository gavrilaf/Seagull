import NIOHTTP1

public enum SgResult {
    case data(response: SgDataResponse)
    case file(response: SgFileResponse)
    case error(response: SgErrorResponse)
}

extension SgResult: CustomStringConvertible {
    public var httpCode: HTTPResponseStatus {
        switch self {
        case .data(let r):
            return r.code
        case .file(let r):
            return r.code
        case .error(let r):
            return r.response.code
        }
    }
    
    public var description: String {
        switch self {
        case .data(let r):
            return "\(r.code), data lenth \(r.body?.count ?? 0)"
        case .file(let r):
            return "\(r.code), file path: \(r.path)"
        case .error(let r):
            return "\(r.response.code),  \(r.localizedDescription)"
        }
    }
}
