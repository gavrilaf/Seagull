import Foundation
import NIOHTTP1

struct UriParser {
    
    static let trimmedChars = CharacterSet(charactersIn: " /")
    
    init(uri: String) {
        let trimmed = uri.trimmingCharacters(in: UriParser.trimmedChars)
        pathComponents = NSString(string: trimmed).pathComponents
    }
    
    let pathComponents: [String]
}

