import Foundation
import NIOHTTP1

public struct Headers {
    
    public struct MIME {
        public static let text = HTTPHeaders([("Content-Type", "text/plain")])
        public static let json = HTTPHeaders([("Content-Type", "application/json")])
    }
}


