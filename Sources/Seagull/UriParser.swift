import Foundation
import NIOHTTP1

struct UriParser {
    
    static let trimmedChars = CharacterSet(charactersIn: " /")
    
    init(uri: String) {
        let components = URLComponents(string: uri.trimmingCharacters(in: UriParser.trimmedChars))
        
        pathComponents = NSString(string: components?.path ?? "").pathComponents
        
        var params = [String: String]()
        components?.queryItems?.forEach { (queryItem) in
            params[queryItem.name] = queryItem.value ?? ""
        }
        
        queryParams = params
    }
    
    let pathComponents: [String]
    let queryParams: [String: String]
}

