//
//  LinuxShim.swift
//  UTM
//

#if !os(macOS)
import Foundation

public typealias ObservableObject = AnyObject

@propertyWrapper
public struct Published<Value> {
    public var wrappedValue: Value
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    public init(initialValue: Value) {
        self.wrappedValue = initialValue
    }
    
    public var projectedValue: Published<Value> {
        self
    }
}
#endif

// Shared shims (available on macOS too if missing)
enum UTMQEMUSoundBackend: Int {
    case qemuSoundBackendDefault = 0
    case qemuSoundBackendCoreAudio = 1
    case qemuSoundBackendMax
}

// MARK: - UTMCapabilities Shim
struct UTMCapabilities {
    struct Capabilities: OptionSet {
        let rawValue: Int
        
        static let hasHypervisorSupport = Capabilities(rawValue: 1 << 0)
        static let isAarch64 = Capabilities(rawValue: 1 << 1)
        static let isX86_64 = Capabilities(rawValue: 1 << 2)
    }
    
    static let current: Capabilities = {
        var caps: Capabilities = []
        #if canImport(Virtualization)
        // macOS logic would go here
        #endif
        // Simple architecture detection for Linux
        #if arch(arm64)
        caps.insert(.isAarch64)
        #elseif arch(x86_64)
        caps.insert(.isX86_64)
        #endif
        
        // Check for KVM support (basic check for /dev/kvm)
        if FileManager.default.fileExists(atPath: "/dev/kvm") {
             caps.insert(.hasHypervisorSupport)
        }
        return caps
    }()
}

struct Logger {
    init(subsystem: String, category: String) {}
    func error(_ msg: String) { print("ERROR: \(msg)") }
    func warning(_ msg: String) { print("WARNING: \(msg)") }
    func info(_ msg: String) { print("INFO: \(msg)") }
    func debug(_ msg: String) { print("DEBUG: \(msg)") }
}


let logger = Logger(subsystem: "com.utmapp.UTM", category: "Configuration")

struct UTMData {
    static func newImage(from fileURL: URL, to directoryURL: URL) -> URL {
        let name = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension
        var newURL = directoryURL.appendingPathComponent(fileURL.lastPathComponent)
        var i = 1
        while FileManager.default.fileExists(atPath: newURL.path) {
            newURL = directoryURL.appendingPathComponent("\(name)-\(i).\(ext)")
            i += 1
        }
        return newURL
    }
}
