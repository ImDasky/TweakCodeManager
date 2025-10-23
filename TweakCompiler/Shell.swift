import Foundation
import Darwin

// Shell command execution using posix_spawn
@_silgen_name("posix_spawnattr_set_persona_np")
func posix_spawnattr_set_persona_np(_ attr: UnsafeMutablePointer<posix_spawnattr_t?>, _ persona_id: uid_t, _ flags: UInt32)

@_silgen_name("posix_spawnattr_set_persona_uid_np")
func posix_spawnattr_set_persona_uid_np(_ attr: UnsafeMutablePointer<posix_spawnattr_t?>, _ persona_id: uid_t)

@_silgen_name("posix_spawnattr_set_persona_gid_np")
func posix_spawnattr_set_persona_gid_np(_ attr: UnsafeMutablePointer<posix_spawnattr_t?>, _ persona_id: uid_t)

/// Execute a shell command and capture output
/// - Parameters:
///   - command: The command to execute (e.g., "make", "ls")
///   - arguments: Command arguments
///   - workingDirectory: Working directory for command execution
///   - uid: User ID to run as (default: 501)
/// - Returns: Tuple of (exitCode, stdout, stderr)
func executeCommand(
    _ command: String,
    arguments: [String] = [],
    workingDirectory: String? = nil,
    uid: uid_t = 501
) -> (exitCode: Int, stdout: String, stderr: String) {
    // Create pipes for stdout and stderr
    var stdoutPipe: [Int32] = [0, 0]
    var stderrPipe: [Int32] = [0, 0]
    
    guard pipe(&stdoutPipe) == 0, pipe(&stderrPipe) == 0 else {
        return (-1, "", "Failed to create pipes")
    }
    
    defer {
        close(stdoutPipe[0])
        close(stdoutPipe[1])
        close(stderrPipe[0])
        close(stderrPipe[1])
    }
    
    var pid: pid_t = 0
    
    // If working directory is specified, wrap command in shell that changes directory
    let finalCommand: String
    let finalArguments: [String]
    
    if let workDir = workingDirectory {
        finalCommand = "/var/jb/usr/bin/bash"
        let commandString = ([command] + arguments).map { arg in
            // Escape single quotes in arguments
            "'\(arg.replacingOccurrences(of: "'", with: "'\\''"))'"
        }.joined(separator: " ")
        finalArguments = ["-c", "cd '\(workDir.replacingOccurrences(of: "'", with: "'\\''"))' && \(commandString)"]
    } else {
        finalCommand = command
        finalArguments = arguments
    }
    
    let argv: [UnsafeMutablePointer<CChar>?] = ([String(finalCommand.split(separator: "/").last!)] + finalArguments).map { $0.withCString(strdup) }
    defer { for case let arg? in argv { free(arg) } }
    
    // Set up environment
    let theosPath = "/var/theos"
    let envStrings = [
        "PATH=/var/jb/usr/bin:/var/jb/bin:/usr/bin:/bin:/usr/sbin:/sbin",
        "HOME=\(NSHomeDirectory())",
        "TMPDIR=\(NSTemporaryDirectory())",
        "THEOS=\(theosPath)",
        "THEOS_MAKE_PATH=\(theosPath)/makefiles",
        "THEOS_BIN_PATH=\(theosPath)/bin",
        "THEOS_LIBRARY_PATH=\(theosPath)/lib",
        "THEOS_INCLUDE_PATH=\(theosPath)/include",
        "THEOS_VENDOR_LIBRARY_PATH=\(theosPath)/vendor/lib",
        "THEOS_VENDOR_INCLUDE_PATH=\(theosPath)/vendor/include",
        "THEOS_DEVICE_IP=localhost",
        "THEOS_DEVICE_PORT=22",
        "THEOS_PACKAGE_SCHEME=rootless"
    ]
    
    let env: [UnsafeMutablePointer<CChar>?] = envStrings.map { $0.withCString(strdup) }
    defer { for case let e? in env { free(e) } }
    
    // Set up file actions for pipes
    var fileActions: posix_spawn_file_actions_t?
    posix_spawn_file_actions_init(&fileActions)
    posix_spawn_file_actions_adddup2(&fileActions, stdoutPipe[1], STDOUT_FILENO)
    posix_spawn_file_actions_adddup2(&fileActions, stderrPipe[1], STDERR_FILENO)
    posix_spawn_file_actions_addclose(&fileActions, stdoutPipe[0])
    posix_spawn_file_actions_addclose(&fileActions, stderrPipe[0])
    
    // Set up spawn attributes
    var attr: posix_spawnattr_t?
    posix_spawnattr_init(&attr)
    posix_spawnattr_set_persona_np(&attr, 99, 1)
    posix_spawnattr_set_persona_uid_np(&attr, uid)
    posix_spawnattr_set_persona_gid_np(&attr, uid)
    
    // Determine command path
    let commandPath: String
    if finalCommand.starts(with: "/") {
        commandPath = finalCommand
    } else {
        // Try common paths
        let searchPaths = ["/var/jb/usr/bin", "/var/jb/bin", "/usr/bin", "/bin"]
        if let foundPath = searchPaths.first(where: { FileManager.default.fileExists(atPath: "\($0)/\(finalCommand)") }) {
            commandPath = "\(foundPath)/\(finalCommand)"
        } else {
            commandPath = finalCommand
        }
    }
    
    // Spawn process
    let spawnResult = posix_spawn(&pid, commandPath, &fileActions, &attr, argv + [nil], env + [nil])
    
    posix_spawn_file_actions_destroy(&fileActions)
    posix_spawnattr_destroy(&attr)
    
    guard spawnResult == 0 else {
        return (-1, "", "Failed to spawn process: \(String(cString: strerror(spawnResult)))")
    }
    
    // Close write ends of pipes
    close(stdoutPipe[1])
    close(stderrPipe[1])
    
    // Read output
    var stdoutData = Data()
    var stderrData = Data()
    
    let bufferSize = 4096
    var buffer = [UInt8](repeating: 0, count: bufferSize)
    
    // Read stdout
    while true {
        let bytesRead = read(stdoutPipe[0], &buffer, bufferSize)
        if bytesRead <= 0 { break }
        stdoutData.append(contentsOf: buffer[0..<bytesRead])
    }
    
    // Read stderr
    while true {
        let bytesRead = read(stderrPipe[0], &buffer, bufferSize)
        if bytesRead <= 0 { break }
        stderrData.append(contentsOf: buffer[0..<bytesRead])
    }
    
    // Wait for process to complete
    var status: Int32 = 0
    waitpid(pid, &status, 0)
    
    // Extract exit code from status (equivalent to WEXITSTATUS macro)
    let exitCode = Int((status >> 8) & 0xFF)
    let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
    let stderr = String(data: stderrData, encoding: .utf8) ?? ""
    
    return (exitCode, stdout, stderr)
}

/// Simple shell command execution without capturing output
@discardableResult
func shell(_ command: String, uid: uid_t = 501, workingDirectory: String? = nil) -> Int {
    let result = executeCommand("/var/jb/usr/bin/bash", arguments: ["-c", command], workingDirectory: workingDirectory, uid: uid)
    return result.exitCode
}

