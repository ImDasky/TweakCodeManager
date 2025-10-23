import Foundation
import SwiftUI

class CompilationManager: ObservableObject {
    @Published var isCompiling = false
    @Published var compilationLog: [LogEntry] = []
    @Published var compilationProgress: Double = 0.0
    @Published var lastCompilationResult: CompilationResult?
    @Published var lastPackagePath: String?
    
    private var isRunning = false
    
    func compileProject(_ project: TweakProject) {
        guard !isCompiling else { return }
        
        isCompiling = true
        compilationLog.removeAll()
        compilationProgress = 0.0
        lastPackagePath = nil
        
        addLog("Starting compilation for \(project.name)...", type: .info)
        addLog("Project path: \(project.path.path)", type: .info)
        
        // Run actual Theos compilation
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.runTheosCompilation(project)
        }
    }
    
    private func runTheosCompilation(_ project: TweakProject) {
        let projectPath = project.path.path
        
        // Step 1: Check if Makefile exists
        DispatchQueue.main.async { [weak self] in
            self?.addLog("Checking project structure...", type: .output)
            self?.compilationProgress = 0.1
        }
        
        let makefilePath = "\(projectPath)/Makefile"
        guard FileManager.default.fileExists(atPath: makefilePath) else {
            DispatchQueue.main.async { [weak self] in
                self?.addLog("Error: Makefile not found at \(makefilePath)", type: .error)
                self?.handleCompilationResult(false, project, packagePath: nil)
            }
            return
        }
        
        // Step 1.5: Check and fix Makefile if it has hardcoded paths
        if let makefileContent = try? String(contentsOfFile: makefilePath, encoding: .utf8) {
            var needsFix = false
            var fixedContent = makefileContent
            
            // Check for hardcoded Mac paths (but not in variable assignments)
            if makefileContent.contains("/Users/") && makefileContent.contains("/theos") {
                DispatchQueue.main.async { [weak self] in
                    self?.addLog("⚠️ Detected hardcoded Theos paths, fixing...", type: .warning)
                }
                
                // Process line by line to avoid replacing THEOS variable definitions
                let lines = makefileContent.components(separatedBy: .newlines)
                var fixedLines: [String] = []
                
                for line in lines {
                    var fixedLine = line
                    
                    // Skip lines that are defining THEOS variable (export THEOS = ...)
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    if trimmedLine.hasPrefix("export THEOS") || 
                       trimmedLine.hasPrefix("THEOS =") ||
                       trimmedLine.hasPrefix("THEOS=") {
                        // For THEOS definitions, just remove them (we set it via environment)
                        if trimmedLine.hasPrefix("export THEOS") || trimmedLine.hasPrefix("THEOS") {
                            fixedLine = "# \(line) # Auto-commented: THEOS set via environment"
                            needsFix = true
                        }
                    } else if line.contains("/Users/") && line.contains("/theos") {
                        // Replace hardcoded paths in include statements or other uses
                        fixedLine = line.replacingOccurrences(
                            of: #"/Users/[^/\s]+/theos"#,
                            with: "$(THEOS)",
                            options: .regularExpression
                        )
                        needsFix = true
                    }
                    
                    fixedLines.append(fixedLine)
                }
                
                if needsFix {
                    fixedContent = fixedLines.joined(separator: "\n")
                }
            }
            
            if needsFix {
                do {
                    try fixedContent.write(toFile: makefilePath, atomically: true, encoding: .utf8)
                    DispatchQueue.main.async { [weak self] in
                        self?.addLog("✅ Fixed Makefile paths", type: .success)
                    }
                } catch {
                    DispatchQueue.main.async { [weak self] in
                        self?.addLog("⚠️ Could not fix Makefile: \(error.localizedDescription)", type: .warning)
                    }
                }
            }
        }
        
        // Step 2: Create packages directory if it doesn't exist
        let packagesPath = "\(projectPath)/packages"
        if !FileManager.default.fileExists(atPath: packagesPath) {
            do {
                try FileManager.default.createDirectory(atPath: packagesPath, withIntermediateDirectories: true)
                DispatchQueue.main.async { [weak self] in
                    self?.addLog("Created packages directory", type: .output)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.addLog("Warning: Could not create packages directory: \(error.localizedDescription)", type: .warning)
                }
            }
        }
        
        // Step 3: Run make clean
        DispatchQueue.main.async { [weak self] in
            self?.addLog("Cleaning previous build...", type: .output)
            self?.compilationProgress = 0.2
        }
        
        _ = executeCommand("make", arguments: ["clean"], workingDirectory: projectPath)
        
        // Step 4: Run make package
        DispatchQueue.main.async { [weak self] in
            self?.addLog("Building tweak...", type: .output)
            self?.compilationProgress = 0.4
        }
        
        let (makeExitCode, makeOutput, makeError) = executeCommand("make", arguments: ["package"], workingDirectory: projectPath)
        let makeSuccess = makeExitCode == 0
        
        // Log output
        if !makeOutput.isEmpty {
            let lines = makeOutput.components(separatedBy: .newlines).filter { !$0.isEmpty }
            for line in lines {
                DispatchQueue.main.async { [weak self] in
                    self?.addLog(line, type: .output)
                }
            }
        }
        
        if !makeError.isEmpty {
            let lines = makeError.components(separatedBy: .newlines).filter { !$0.isEmpty }
            for line in lines {
                DispatchQueue.main.async { [weak self] in
                    self?.addLog(line, type: makeSuccess ? .warning : .error)
                }
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.compilationProgress = 0.8
        }
        
        // Step 5: Find the generated .deb package
        var packagePath: String?
        if makeSuccess {
            DispatchQueue.main.async { [weak self] in
                self?.addLog("Looking for generated package...", type: .output)
            }
            
            // Check in packages directory
            if let debFiles = try? FileManager.default.contentsOfDirectory(atPath: packagesPath) {
                let sortedDebs = debFiles.filter { $0.hasSuffix(".deb") }.sorted { (file1, file2) -> Bool in
                    let path1 = "\(packagesPath)/\(file1)"
                    let path2 = "\(packagesPath)/\(file2)"
                    
                    guard let attr1 = try? FileManager.default.attributesOfItem(atPath: path1),
                          let attr2 = try? FileManager.default.attributesOfItem(atPath: path2),
                          let date1 = attr1[.modificationDate] as? Date,
                          let date2 = attr2[.modificationDate] as? Date else {
                        return false
                    }
                    
                    return date1 > date2
                }
                
                if let latestDeb = sortedDebs.first {
                    packagePath = "\(packagesPath)/\(latestDeb)"
                }
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.compilationProgress = 1.0
            self?.handleCompilationResult(makeSuccess, project, packagePath: packagePath)
        }
    }
    
    private func handleCompilationResult(_ success: Bool, _ project: TweakProject, packagePath: String?) {
        isCompiling = false
        compilationProgress = 1.0
        isRunning = false
        lastPackagePath = packagePath
        
        if success {
            addLog("✅ Compilation successful!", type: .success)
            if let packagePath = packagePath {
                let packageName = URL(fileURLWithPath: packagePath).lastPathComponent
                addLog("📦 Package created: \(packageName)", type: .success)
                addLog("📁 Location: \(packagePath)", type: .info)
            } else {
                addLog("⚠️ Package may have been created but could not be located", type: .warning)
            }
            lastCompilationResult = CompilationResult(success: true, project: project)
        } else {
            addLog("❌ Compilation failed", type: .error)
            addLog("Check the log above for errors", type: .error)
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
        isRunning = false
        addLog("⚠️ Compilation stopped by user (note: current process will complete)", type: .warning)
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
