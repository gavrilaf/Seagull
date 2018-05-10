import Foundation
import NIOHTTP1

struct PathBuilder {
    
    init(method: HTTPMethod, uri: String) {
        let components = (uri as NSString).pathComponents
        
        var index = 0
        while index < components.count && components[index] == "/" {
            index += 1
        }
        
        var t = Array(components[index...])
        t.append(method.str)
        
        pathComponents = t
    }
    
    let pathComponents: [String]
}

