import Foundation
import Configuration

@MainActor
class VMStore {
    static let shared = VMStore()
    
    var vms: [UTMQemuConfiguration] = []
    
    private let fileManager = FileManager.default
    
    var dataHome: URL {
        if let xdgDataHome = ProcessInfo.processInfo.environment["XDG_DATA_HOME"] {
            return URL(fileURLWithPath: xdgDataHome).appendingPathComponent("UTM")
        } else {
            return fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent(".local")
                .appendingPathComponent("share")
                .appendingPathComponent("UTM")
        }
    }
    
    init() {
        reload()
    }
    
    func reload() {
        // Ensure directory exists
        if !fileManager.fileExists(atPath: dataHome.path) {
            try? fileManager.createDirectory(at: dataHome, withIntermediateDirectories: true)
        }
        
        guard let files = try? fileManager.contentsOfDirectory(at: dataHome, includingPropertiesForKeys: nil) else {
            return
        }
        
        var newVMs: [UTMQemuConfiguration] = []
        for file in files {
            if file.pathExtension == "utm" {
                if let config = try? UTMQemuConfiguration.load(from: file) as? UTMQemuConfiguration {
                    newVMs.append(config)
                }
            }
        }
        self.vms = newVMs
    }
    
    func add(_ config: UTMQemuConfiguration) {
        let name = config.information.name
        let vmPath = dataHome.appendingPathComponent(name).appendingPathExtension("utm")
        
        do {
            if !fileManager.fileExists(atPath: vmPath.path) {
                try fileManager.createDirectory(at: vmPath, withIntermediateDirectories: true)
            }
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let data = try encoder.encode(config)
            try data.write(to: vmPath.appendingPathComponent("config.plist"))
            
            self.vms.append(config)
        } catch {
            print("Failed to save VM: \(error)")
        }
    }
    
    func remove(_ config: UTMQemuConfiguration) {
        let name = config.information.name
        let vmPath = dataHome.appendingPathComponent(name).appendingPathExtension("utm")
        
        do {
            if fileManager.fileExists(atPath: vmPath.path) {
                try fileManager.removeItem(at: vmPath)
            }
        } catch {
            print("Failed to delete VM file: \(error)")
        }
        
        if let index = vms.firstIndex(where: { $0.id == config.id }) {
            vms.remove(at: index)
        }
    }
}
