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

enum DataError: Error {
    case emptyBody
    case invalidJson(Error)
}


// MARK: -

class Db {
    
    static let inst = Db()
    
    // MARK: -
    
    func register(_ user: LoginDTO) -> Result<AuthTokenDTO, APIError> {
        return lock.withLock { () -> Result<AuthTokenDTO, APIError> in
            if self.users[user.username] != nil {
                return Result(error: APIError.alreadyRegistered(user.username))
            }
            
            self.users[user.username] = user.password
            self.profiles[user.username] = ProfileDTO(firstName: "", lastName: "", country: "UA")
            
            return Result(value: self.doLogin(username: user.username))
        }
    }
    
    func login(_ user: LoginDTO) -> Result<AuthTokenDTO, APIError> {
        return lock.withLock { () -> Result<AuthTokenDTO, APIError> in
            if self.users[user.username] != user.password {
                return Result(error: APIError.userNotFound)
            }
            
            return Result(value: self.doLogin(username: user.username))
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

func decode<T: Decodable>(_ t: T.Type, request: SgRequest) throws -> T {
    guard let body = request.body else {
        throw DataError.emptyBody
    }
    
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(t, from: body)
    } catch let e {
        throw DataError.invalidJson(e)
    }
}

// MARK: -

struct Handlers {
    
    static func register(_ request: SgRequest, _ context: SgRequestContext) -> SgResult {
        do {
            let dto = try decode(LoginDTO.self, request: request)
            
            switch Db.inst.register(dto) {
            case .success(let token):
                return SgResult.data(response: try SgDataResponse.from(json: token))
            case .failure(let error):
                throw error
            }
        } catch let e {
            return SgResult.error(response: SgErrorResponse.from(error: e))
        }
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
