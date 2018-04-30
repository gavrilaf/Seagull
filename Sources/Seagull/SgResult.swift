import Foundation

public enum SgResult {
    case data(response: SgDataResponse)
    case file(response: SgFileResponse)
}

extension SgResult {
    public static func from(string: String) -> SgResult {
        return .data(response: SgDataResponse.from(string: string))
    }
    
    public static func from(error: Error) -> SgResult {
        return .data(response: SgDataResponse.from(error: error))
    }
}
