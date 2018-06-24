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
        if self.users.get(key: user.username) != nil {
            throw AppLogicError.alreadyRegistered(user.username)
        }
            
        self.users.set(value: user.password, forKey: user.username)
        self.profiles.set(value: ProfileDTO(firstName: "", lastName: "", country: "UA"), forKey: user.username)
            
        return self.doLogin(username: user.username)
    }
    
    func login(user: LoginDTO) throws -> AuthTokenDTO {
        if self.users.get(key: user.username) != user.password {
            throw AppLogicError.userNotFound(user.username)
        }
            
        return self.doLogin(username: user.username)
    }
    
    func logout(token: String) {
        self.sessions.remove(key: token)
    }
    
    // MARK: -
    func getProfile(username: String) throws -> ProfileDTO {
        guard let profile = self.profiles.get(key: username) else {
            throw AppLogicError.userNotFound(username)
        }
            
        return profile
    }
    
    func updateProfile(username: String, profile: ProfileDTO) {
        self.profiles.set(value: profile, forKey: username)
    }
    
    func deleteUser(token: String) throws {
        let username = try getUsername(forToken: token)
        
        self.sessions.remove(key: token)
        self.profiles.remove(key: username)
        self.users.remove(key: username)
    }
    
    // MARK: -
    private func doLogin(username: String) -> AuthTokenDTO {
        let token = "token-\(self.counter)"
        sessions.set(value: username, forKey: token)
        counter += 1
        return AuthTokenDTO(token: token)
    }
    
    func getUsername(forToken token: String) throws -> String {
        guard let username = self.sessions.get(key: token) else {
            throw AppLogicError.tokenNotFound
        }
        
        return username
    }
    
    // MARK: -
    private var counter: Int64 = 0
    
    private var users = SafeMap<String, String>()
    private var sessions = SafeMap<String, String>()
    private var profiles = SafeMap<String, ProfileDTO>()
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
    static func ping(_ : SgRequest, _ : SgRequestContext) -> SgResult {
        return SgResult.data(response: SgDataResponse.from(string: "SgBaseRest ping ok"))
    }
    
    // MARK: -
    static func register(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        do {
            let loginDTO = try ctx.decode(LoginDTO.self, request: request)
            let token = try Db.inst.register(user: loginDTO)
            return ctx.encode(json: token)
        } catch let err {
            return ctx.error(err)
        }
    }
    
    static func login(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        do {
            let loginDTO = try ctx.decode(LoginDTO.self, request: request)
            let token = try Db.inst.login(user: loginDTO)
            return ctx.encode(json: token)
        } catch let err {
            return ctx.error(err)
        }
    }
    
    // MARK: -
    static func getMyProfile(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        do {
            let token = ctx.string(forKey: "token")
            let username = try Db.inst.getUsername(forToken: token)
            let profile = try Db.inst.getProfile(username: username)
            
            return ctx.encode(json: profile)
        } catch let err {
            return ctx.error(err)
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
            return ctx.error(err)
        }
    }
    
    static func updateProfile(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        do {
            let username = try Db.inst.getUsername(forToken: ctx.string(forKey: "token"))
            let profile = try ctx.decode(ProfileDTO.self, request: request)
            
            Db.inst.updateProfile(username: username, profile: profile)
            return SgResult.data(response: SgDataResponse.empty())
            
        } catch let err {
            return ctx.error(err)
        }
    }
    
    static func deleteProfile(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        do {
            try Db.inst.deleteUser(token: ctx.string(forKey: "token"))
            return ctx.empty()
        } catch let err {
            return ctx.error(err)
        }
    }
    
    static func logout(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        Db.inst.logout(token: ctx.string(forKey: "token"))
        return ctx.empty()
    }
    
    static func whoami(_ request: SgRequest, _ ctx: SgRequestContext) -> SgResult {
        do {
            let username = try Db.inst.getUsername(forToken: ctx.string(forKey: "token"))
            return ctx.encode(dict: ["username": username])
        } catch let err {
            return ctx.error(err)
        }
    }
}
