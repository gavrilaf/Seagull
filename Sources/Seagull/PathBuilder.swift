import Foundation
import NIOHTTP1

struct PathBuilder {
    
    static let trimmedChars = CharacterSet(charactersIn: " /")
    
    init(method: HTTPMethod, uri: String) {
        let trimmed = uri.trimmingCharacters(in: PathBuilder.trimmedChars)
        var components = (trimmed as NSString).pathComponents
        components.append(method.str)
        pathComponents = components
    }
    
    let pathComponents: [String]
}

