import Foundation
import SwiftUI

class CompilationManager: ObservableObject {
    @Published var isCompiling = false
    @Published var compilationLog: [LogEntry] = []
    @Published var compilationProgress: Double = 0.0
    @Published var lastCompilationResult: CompilationResult?
    
    func compileProject(_ project: TweakProject) {
        guard !isCompiling else { return }
        
        isCompiling = true
        compilationLog.removeAll()
        compilationProgress = 0.0
        
        addLog("Starting compilation for \(project.name)...", type: .info)
        
        // Simulate compilation process
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.simulateCompilation(project)
        }
    }
    
    private func simulateCompilation(_ project: TweakProject) {
        // Simulate compilation steps
        let steps = [
            "Checking project structure...",
            "Validating source files...",
            "Compiling Swift code...",
            "Linking frameworks...",
            "Generating package...",
            "Creating .deb file..."
        ]
        
        for (index, step) in steps.enumerated() {
            Thread.sleep(forTimeInterval: 0.5)
            
            DispatchQueue.main.async { [weak self] in
                self?.addLog(step, type: .output)
                self?.compilationProgress = Double(index + 1) / Double(steps.count)
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.handleCompilationResult(true, project)
        }
    }
    
    private func handleCompilationResult(_ success: Bool, _ project: TweakProject) {
        isCompiling = false
        compilationProgress = 1.0
        
        if success {
            addLog("Compilation successful!", type: .success)
            addLog("Package created: \(project.name)_1.0.0_iphoneos-arm.deb", type: .success)
            lastCompilationResult = CompilationResult(success: true, project: project)
        } else {
            addLog("Compilation failed", type: .error)
            lastCompilationResult = CompilationResult(success: false, project: project)
        }
    }
    
    func addLog(_ message: String, type: LogType = .info) {
        let entry = LogEntry(message: message, type: type, timestamp: Date())
        compilationLog.append(entry)
    }
    
    func clearLog() {
        compilationLog.removeAll()
    }
    
    func stopCompilation() {
        isCompiling = false
        addLog("Compilation stopped by user", type: .warning)
    }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let message: String
    let type: LogType
    let timestamp: Date
}

enum LogType {
    case info
    case success
    case warning
    case error
    case output
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .output: return .primary
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .output: return "terminal"
        }
    }
}

struct CompilationResult {
    let success: Bool
    let project: TweakProject
    let timestamp = Date()
}
