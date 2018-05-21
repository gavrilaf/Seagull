import Foundation
import NIOConcurrencyHelpers
import Seagull
import Result

// MARK: - Model

struct LoginDTO: Codable {
    let username: String
    let password: String
}

struct AuthTokenDTO: Codable {
    let token: String
}

struct ProfileDTO: Codable {
    
    init(firstName: String, lastName: String, country: String) {
        self.personal = PersonalInfo(firstName: firstName, lastName: lastName)
        self.country = country
    }
    
    struct PersonalInfo: Codable {
        let firstName: String
        let lastName: String
    }
    
    let personal: PersonalInfo
    let country: String
}

enum APIError: Error {
    case alreadyRegistered(String)
    case userNotFound
    case invalidToken
}

// MARK: -

class Db {
    
    static let inst = Db()
    
    // MARK: -
    
    func register(_ user: LoginDTO) throws -> AuthTokenDTO {
        return try lock.withLock {
            if self.users[user.username] != nil {
                throw APIError.alreadyRegistered(user.username)
            }
            
            self.users[user.username] = user.password
            self.profiles[user.username] = ProfileDTO(firstName: "", lastName: "", country: "UA")
            
            return self.doLogin(username: user.username)
        }
    }
    
    func login(_ user: LoginDTO) throws -> AuthTokenDTO {
        return try lock.withLock {
            if self.users[user.username] != user.password {
                throw APIError.userNotFound
            }
            
            return self.doLogin(username: user.username)
        }
    }
    
    // MARK: -
    //func getProfile(_ username: String) -> Result<AuthTokenDTO, APIError> {
    
    // MARK: -
    private func doLogin(username: String) -> AuthTokenDTO {
        let token = "token-\(self.counter)"
        sessions[token] = username
        counter += 1
        return AuthTokenDTO(token: token)
    }
    
    private let lock = Lock()
    
    private var counter: Int64 = 0
    
    private var users = [String: String]()
    private var sessions = [String: String]()
    private var profiles = [String: ProfileDTO]()
}

// MARK: -

struct Handlers {
    
    static func register(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        do {
            let loginDTO = try ctx.decode(LoginDTO.self, request: request)
            let token = try Db.inst.register(loginDTO)
            return ctx.encode(json: token)
        } catch let err {
            return SgResult.error(response: ctx.errorProvider.generalError(err))
        }
    }
    
    static func login(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        return SgResult.error(response: SgErrorResponse.from(string: "Not implemented", code: .internalServerError))
    }
    
    static func getProfile(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        return SgResult.error(response: SgErrorResponse.from(string: "Not implemented", code: .internalServerError))
    }
    
    static func updateProfile(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        return SgResult.error(response: SgErrorResponse.from(string: "Not implemented", code: .internalServerError))
    }
    
    static func deleteProfile(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        return SgResult.error(response: SgErrorResponse.from(string: "Not implemented", code: .internalServerError))
    }
    
    static func logout(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        return SgResult.error(response: SgErrorResponse.from(string: "Not implemented", code: .internalServerError))
    }
}
