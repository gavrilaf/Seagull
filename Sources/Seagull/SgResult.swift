import Foundation

public enum SgResult {
    case data(response: SgDataResponse)
    case file(response: SgFileResponse)
    case error(response: SgErrorResponse)
}
