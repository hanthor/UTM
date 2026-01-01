import Foundation

struct Logger {
    let subsystem: String
    let category: String
    
    init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }
    
    func error(_ msg: String) { print("[\(category)] ERROR: \(msg)") }
    func warning(_ msg: String) { print("[\(category)] WARNING: \(msg)") }
    func info(_ msg: String) { print("[\(category)] INFO: \(msg)") }
    func debug(_ msg: String) { print("[\(category)] DEBUG: \(msg)") }
}
