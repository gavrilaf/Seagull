import Foundation

class PathMap<Element> {
    
    struct Destination {
        let value: Element
        let pathParams: [String: String]
        let queryParams: [String: String]
    }
    
    func add(path: String, _ p: Element) {
        tree[path] = p
    }
    
    func get(path: String) -> Destination? {
        guard let p = tree[path] else { return nil }
        return Destination(value: p, pathParams: [:], queryParams: [:])
    }
    
    private var tree = [String: Element]()
}
