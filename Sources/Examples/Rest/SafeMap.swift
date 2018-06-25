import Foundation
import Dispatch

class SafeMap<T: Hashable, E> {
    
    private let queue = DispatchQueue(label:"", attributes: .concurrent)
    private var map = [T: E]()
    
    func get(key: T) -> E? {
        var result: E?
        queue.sync { result = self.map[key] }
        return result
    }
    
    func set(value: E, forKey key: T) {
        queue.async(flags: .barrier) {
            self.map[key] = value
        }
    }
    
    func remove(key: T) {
        queue.async(flags: .barrier) {
            self.map.removeValue(forKey: key)
        }
    }
}
