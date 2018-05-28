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

enum AppLogicError: LocalizedError {
    case invalidParam
    case alreadyRegistered(String)
    case userNotFound(String)
    case tokenNotFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidParam:
            return "invalidParam"
        case .alreadyRegistered(let user):
            return "alreadyRegistered(\(user))"
        case .userNotFound(let user):
            return "userNotFound(\(user))"
        case .tokenNotFound:
            return "tokenNotFound"
        }
    }
}

// MARK: -

class Db {
    
    static let inst = Db()
    
    // MARK: -
    
    func register(user: LoginDTO) throws -> AuthTokenDTO {
        return try lock.withLock {
            if self.users[user.username] != nil {
                throw AppLogicError.alreadyRegistered(user.username)
            }
            
            self.users[user.username] = user.password
            self.profiles[user.username] = ProfileDTO(firstName: "", lastName: "", country: "UA")
            
            return self.doLogin(username: user.username)
        }
    }
    
    func login(user: LoginDTO) throws -> AuthTokenDTO {
        return try lock.withLock {
            if self.users[user.username] != user.password {
                throw AppLogicError.userNotFound(user.username)
            }
            
            return self.doLogin(username: user.username)
        }
    }
    
    func getUsername(forToken token: String) throws -> String {
        return try lock.withLock {
            guard let username = self.sessions[token] else {
                throw AppLogicError.tokenNotFound
            }
            
            return username
        }
    }
    
    // MARK: -
    func getProfile(username: String) throws -> ProfileDTO {
        return try lock.withLock {
            guard let profile = self.profiles[username] else {
                throw AppLogicError.userNotFound(username)
            }
            
            return profile
        }
    }
    
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
    
    static func tokenMiddleware(_ request: SgRequest, _ ctx: SgRequestContext) -> MiddlewareResult {
        if let token = request.headers[canonicalForm: "Authorization"].first {
            var mutableCtx = ctx
            mutableCtx.set(value: token, forKey: "token")
            return MiddlewareResult(value: mutableCtx)
        } else {
            return MiddlewareResult(error: SgErrorResponse.make(string: "unauthorized", code: .unauthorized))
        }
    }
    
    // MARK: -
    static func register(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        do {
            let loginDTO = try ctx.decode(LoginDTO.self, request: request)
            let token = try Db.inst.register(user: loginDTO)
            return ctx.encode(json: token)
        } catch let err {
            return SgResult.error(response: ctx.errorProvider.generalError(err))
        }
    }
    
    static func login(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        do {
            let loginDTO = try ctx.decode(LoginDTO.self, request: request)
            let token = try Db.inst.login(user: loginDTO)
            return ctx.encode(json: token)
        } catch let err {
            return SgResult.error(response: ctx.errorProvider.generalError(err))
        }
    }
    
    static func getMyProfile(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        do {
            let token = ctx.string(forKey: "token")
            let username = try Db.inst.getUsername(forToken: token)
            let profile = try Db.inst.getProfile(username: username)
            
            return ctx.encode(json: profile)
        } catch let err {
            return SgResult.error(response: ctx.errorProvider.generalError(err))
        }
    }
    
    static func getProfile(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        do {
            _ = try Db.inst.getUsername(forToken: ctx.string(forKey: "token"))
            
            guard let username = request.urlParams["username"] else {
                throw AppLogicError.invalidParam
            }
            
            
            let profile = try Db.inst.getProfile(username: username)
            return ctx.encode(json: profile)
            
        } catch let err {
            return SgResult.error(response: ctx.errorProvider.generalError(err))
        }
    }
    
    static func updateProfile(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        return SgResult.error(response: SgErrorResponse.make(string: "Not implemented", code: .internalServerError))
    }
    
    static func deleteProfile(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        return SgResult.error(response: SgErrorResponse.make(string: "Not implemented", code: .internalServerError))
    }
    
    static func logout(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        return SgResult.error(response: SgErrorResponse.make(string: "Not implemented", code: .internalServerError))
    }
}
