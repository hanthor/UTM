import Foundation
import Configuration

@MainActor
class QEMURunner {
    static let shared = QEMURunner()
    
    private var runningProcesses: [UUID: Process] = [:]
    private let logger = Logger(subsystem: "com.utmapp.UTM", category: "QEMURunner")
    
    func start(_ config: UTMQemuConfiguration) {
        let arch = config.system.architecture.rawValue
        let executable = "/usr/bin/qemu-system-\(arch)"
        
        // Check if QEMU exists
        guard FileManager.default.fileExists(atPath: executable) else {
            logger.error("QEMU executable not found: \(executable)")
            return
        }
        
        let args = config.qemuArguments.map { $0.string }
        
        logger.info("Starting VM: \(config.information.name)")
        logger.debug("Executable: \(executable)")
        logger.debug("Arguments: \(args.joined(separator: " "))")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        
        // Set up pipes for output
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Handle output asynchronously
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                self?.logger.info("[QEMU stdout] \(output)")
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                self?.logger.warning("[QEMU stderr] \(output)")
            }
        }
        
        // Handle termination
        process.terminationHandler = { [weak self] proc in
            Task { @MainActor in
                self?.logger.info("VM \(config.information.name) terminated with code: \(proc.terminationStatus)")
                self?.runningProcesses.removeValue(forKey: config.id)
            }
        }
        
        do {
            try process.run()
            runningProcesses[config.id] = process
            logger.info("VM \(config.information.name) started with PID: \(process.processIdentifier)")
        } catch {
            logger.error("Failed to start VM: \(error.localizedDescription)")
        }
    }
    
    func stop(_ config: UTMQemuConfiguration) {
        guard let process = runningProcesses[config.id] else {
            logger.warning("No running process found for VM: \(config.information.name)")
            return
        }
        
        logger.info("Stopping VM: \(config.information.name)")
        process.terminate()
        runningProcesses.removeValue(forKey: config.id)
    }
    
    func isRunning(_ config: UTMQemuConfiguration) -> Bool {
        return runningProcesses[config.id]?.isRunning ?? false
    }
}
