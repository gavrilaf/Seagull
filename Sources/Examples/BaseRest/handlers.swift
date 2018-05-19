import Foundation
import Seagull

class Db {
    
}


// MARK: -

struct Handlers {
    
    static func register(_ request: SgRequest, _ context: SgRequestContext) -> SgResult {
        return SgResult.error(response: SgErrorResponse.from(string: "Not implemented", code: .internalServerError))
    }
    
    static func login(_ request: SgRequest, _ context: SgRequestContext) -> SgResult {
        return SgResult.error(response: SgErrorResponse.from(string: "Not implemented", code: .internalServerError))
    }
    
    static func getProfile(_ request: SgRequest, _ context: SgRequestContext) -> SgResult {
        return SgResult.error(response: SgErrorResponse.from(string: "Not implemented", code: .internalServerError))
    }
    
    static func updateProfile(_ request: SgRequest, _ context: SgRequestContext) -> SgResult {
        return SgResult.error(response: SgErrorResponse.from(string: "Not implemented", code: .internalServerError))
    }
    
    static func deleteProfile(_ request: SgRequest, _ context: SgRequestContext) -> SgResult {
        return SgResult.error(response: SgErrorResponse.from(string: "Not implemented", code: .internalServerError))
    }
    
    static func logout(_ request: SgRequest, _ context: SgRequestContext) -> SgResult {
        return SgResult.error(response: SgErrorResponse.from(string: "Not implemented", code: .internalServerError))
    }
}
