import Foundation
import SwiftUI
import os
import ObjectiveC

class ProjectManager: ObservableObject {
    @Published var projects: [TweakProject] = []
    @Published var currentProject: TweakProject?
    @Published var isLoading = false
    @Published var creationLog: [String] = []
    
	private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.tweakcompiler.TweakCompiler", category: "ProjectCreation")
	private var projectsPath: URL
    
	init() {
		projectsPath = URL(fileURLWithPath: "/dev/null")
		projectsPath = resolveWritableRoot()
		print("Projects path: \(projectsPath)")
		logger.info("Init ProjectManager projectsPath=\(self.projectsPath.path, privacy: .public)")
		ilog("Init: projectsPath=\(projectsPath.path)")
		loadProjects()
	}
    
    private func ilog(_ message: String) {
        let stamp = ISO8601DateFormatter().string(from: Date())
        DispatchQueue.main.async {
            self.creationLog.append("[\(stamp)] \(message)")
            if self.creationLog.count > 200 {
                self.creationLog.removeFirst(self.creationLog.count - 200)
            }
        }
    }
    
	private func resolveWritableRoot() -> URL {
		// Try MobileContainerManager first (like FridaCodeManager)
		if let containerPath = getMCMContainer() {
			let documentsPath = URL(fileURLWithPath: containerPath).appendingPathComponent("Documents", isDirectory: true)
			let tweakProjectsPath = documentsPath.appendingPathComponent("TweakProjects", isDirectory: true)
			do {
				let fm = FileManager.default
				if !fm.fileExists(atPath: documentsPath.path) {
					try fm.createDirectory(at: documentsPath, withIntermediateDirectories: true)
				}
				if !fm.fileExists(atPath: tweakProjectsPath.path) {
					try fm.createDirectory(at: tweakProjectsPath, withIntermediateDirectories: true)
				}
				let probe = tweakProjectsPath.appendingPathComponent(".permcheck")
				try "ok".write(to: probe, atomically: true, encoding: .utf8)
				try fm.removeItem(at: probe)
				ilog("✅ MCM Container: \(tweakProjectsPath.path)")
				return tweakProjectsPath
			} catch {
				ilog("MCM failed: \(error.localizedDescription)")
			}
		}
		
		// Fallback to standard paths
		let fm = FileManager.default
		let candidates: [URL] = [
			fm.urls(for: .cachesDirectory, in: .userDomainMask).first!,
			fm.temporaryDirectory,
			fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
		]
		for base in candidates {
			let root = base.appendingPathComponent("TweakProjects", isDirectory: true)
			do {
				if !fm.fileExists(atPath: base.path) {
					try fm.createDirectory(at: base, withIntermediateDirectories: true)
				}
				if !fm.fileExists(atPath: root.path) {
					try fm.createDirectory(at: root, withIntermediateDirectories: true)
				}
				let probe = root.appendingPathComponent(".permcheck")
				try "ok".write(to: probe, atomically: true, encoding: .utf8)
				try fm.removeItem(at: probe)
				ilog("Writable root: \(root.path)")
				return root
			} catch {
				logger.error("Root not writable base=\(base.path, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
				ilog("Not writable: \(base.path) — \(error.localizedDescription)")
				continue
			}
		}
		let fallback = FileManager.default.temporaryDirectory.appendingPathComponent("TweakProjects", isDirectory: true)
		return fallback
	}
	
	private func getMCMContainer() -> String? {
		guard let bundleID = Bundle.main.bundleIdentifier else { return nil }
		guard let containerClass = NSClassFromString("MCMAppDataContainer") else {
			ilog("MCMAppDataContainer not available")
			return nil
		}
		let selector = NSSelectorFromString("containerWithIdentifier:createIfNecessary:existed:error:")
		guard (containerClass as AnyObject).responds(to: selector) else {
			ilog("MCM selector not found")
			return nil
		}
		
		// Build NSMethodSignature manually for 4 arguments
		let metaClass = object_getClass(containerClass)
		let method = class_getClassMethod(metaClass, selector)
		guard let method = method else {
			ilog("MCM method not found")
			return nil
		}
		let implementation = method_getImplementation(method)
		typealias MCMFunction = @convention(c) (AnyClass, Selector, NSString, Bool, UnsafeMutablePointer<ObjCBool>, UnsafeMutablePointer<NSError?>) -> AnyObject?
		let function = unsafeBitCast(implementation, to: MCMFunction.self)
		
		var existed: ObjCBool = false
		var error: NSError?
		let container = function(containerClass, selector, bundleID as NSString, true, &existed, &error)
		
		guard let container = container else {
			ilog("MCM container creation failed: \(error?.localizedDescription ?? "unknown")")
			return nil
		}
		if let url = (container as AnyObject).value(forKey: "url") as? URL {
			return url.path
		}
		return nil
	}
    
	func loadProjects() {
		isLoading = true
		logger.info("Loading projects from \(self.projectsPath.path, privacy: .public)")
		ilog("Loading projects… \(projectsPath.path)")
		defer { isLoading = false }
        
        do {
            let projectDirectories = try FileManager.default.contentsOfDirectory(at: projectsPath, includingPropertiesForKeys: [.isDirectoryKey])
            projects = projectDirectories.compactMap { url in
                guard url.hasDirectoryPath else { return nil }
                return TweakProject(from: url)
            }.sorted { $0.name < $1.name }
            logger.info("Loaded \(self.projects.count) projects")
            ilog("Loaded \(projects.count) project(s)")
        } catch {
            logger.error("Error loading projects: \(error.localizedDescription, privacy: .public)")
            print("Error loading projects: \(error)")
            ilog("Error loading: \(error.localizedDescription)")
        }
    }
    
	func createProject(name: String, bundleId: String, targetApp: String) -> TweakProject? {
		logger.info("Creating project name=\(name, privacy: .public) bundleId=\(bundleId, privacy: .public) target=\(targetApp, privacy: .public)")
		ilog("Create tapped: name=\(name), bundle=\(bundleId), target=\(targetApp)")
		projectsPath = resolveWritableRoot()
        
        let projectId = UUID()
        let projectDir = projectsPath.appendingPathComponent(projectId.uuidString)
        let packagesDir = projectDir.appendingPathComponent("packages")
        let makefilePath = projectDir.appendingPathComponent("Makefile")
        let tweakPath = projectDir.appendingPathComponent("Tweak.x")
        let controlPath = projectDir.appendingPathComponent("control")
        let plistPath = projectDir.appendingPathComponent("\(name).plist")
        let infoPath = projectDir.appendingPathComponent("project.json")
        
        do {
            try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: projectDir.path)
            try FileManager.default.createDirectory(at: packagesDir, withIntermediateDirectories: true)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: packagesDir.path)
            logger.info("Created project dir at \(projectDir.path, privacy: .public)")
            ilog("Created dir: \(projectDir.lastPathComponent)")
            
            let makefile = """
            ARCHS = arm64 arm64e
            TARGET := iphone:clang:16.5:14.0
            INSTALL_TARGET_PROCESSES = \(targetApp)
            THEOS_PACKAGE_SCHEME = rootless
            
            include $(THEOS)/makefiles/common.mk
            
            TWEAK_NAME = \(name)
            
            \(name)_FILES = Tweak.x
            \(name)_CFLAGS = -fobjc-arc
            \(name)_FRAMEWORKS = UIKit Foundation
            
            include $(THEOS_MAKE_PATH)/tweak.mk
            """
            
            let tweak = """
            // \(name) - iOS Tweak
            // Hooks into \(targetApp)
            
            #import <Foundation/Foundation.h>
            #import <UIKit/UIKit.h>
            
            // Example hook - modify as needed
            %hook SpringBoard
            
            - (void)applicationDidFinishLaunching:(id)application {
                %orig;
                
                // Your code here
                NSLog(@"[\(name)] Tweak loaded successfully!");
                
                // Show a simple alert to confirm loading
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"\(name)"
                                                                             message:@"Tweak loaded!"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
                });
            }
            
            %end
            
            // Constructor called when the dylib is loaded
            %ctor {
                NSLog(@"[\(name)] Initializing...");
            }
            """
            
            let control = """
            Package: \(bundleId)
            Name: \(name)
            Version: 1.0.0
            Architecture: iphoneos-arm64
            Description: An awesome tweak created with TweakCompiler
            Maintainer: Your Name <you@example.com>
            Author: Your Name <you@example.com>
            Section: Tweaks
            Depends: mobilesubstrate (>= 0.9.5000), firmware (>= 14.0)
            """
            
            let plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Filter</key>
                <dict>
                    <key>Bundles</key>
                    <array>
                        <string>\(targetApp)</string>
                    </array>
                </dict>
            </dict>
            </plist>
            """
            
            try makefile.write(to: makefilePath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: makefilePath.path)
            try tweak.write(to: tweakPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: tweakPath.path)
            try control.write(to: controlPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: controlPath.path)
            try plist.write(to: plistPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: plistPath.path)
            logger.info("Wrote files for project \(name, privacy: .public)")
            ilog("Wrote files: Makefile, Tweak.x, control, \(name).plist")
            
            let project = TweakProject(name: name, bundleId: bundleId, targetApp: targetApp, path: projectDir)
            if let data = try? JSONEncoder().encode(project) {
                FileManager.default.createFile(atPath: infoPath.path, contents: data, attributes: [.protectionKey: FileProtectionType.none])
                logger.info("Saved project.json at \(infoPath.path, privacy: .public)")
                ilog("Saved project.json")
            }
            
            DispatchQueue.main.async {
                self.projects.append(project)
                self.currentProject = project
                self.logger.info("Project created and appended: \(project.name, privacy: .public)")
                self.ilog("Project created: \(project.name)")
            }
            
            return project
        } catch {
            logger.error("Error creating project: \(error.localizedDescription, privacy: .public)")
            print("Error creating project: \(error)")
            ilog("Error creating: \(error.localizedDescription)")
            return nil
        }
    }
    
    func importProject(from zipURL: URL) throws -> (project: TweakProject?, message: String) {
        logger.info("Importing project from \(zipURL.path, privacy: .public)")
        ilog("Import started: \(zipURL.lastPathComponent)")
        
        // Create temporary directory for extraction
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Extract zip file using unzip command
        let zipPath = zipURL.path
        let (exitCode, output, error) = executeCommand("unzip", arguments: ["-q", zipPath, "-d", tempDir.path])
        
        guard exitCode == 0 else {
            ilog("Unzip failed: \(error)")
            throw NSError(domain: "TweakCompiler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract zip: \(error)"])
        }
        
        ilog("Extracted to temp directory")
        
        // Find the root project directory (may be nested)
        let extractedContents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        
        // Look for Makefile to identify project root
        var projectRoot: URL?
        func findProjectRoot(in directory: URL, depth: Int = 0) throws -> URL? {
            if depth > 3 { return nil } // Limit search depth
            
            let makefilePath = directory.appendingPathComponent("Makefile")
            if FileManager.default.fileExists(atPath: makefilePath.path) {
                return directory
            }
            
            // Check subdirectories
            let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey])
            for item in contents {
                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDirectory), isDirectory.boolValue {
                    if let found = try findProjectRoot(in: item, depth: depth + 1) {
                        return found
                    }
                }
            }
            return nil
        }
        
        projectRoot = try findProjectRoot(in: tempDir)
        
        guard let projectRoot = projectRoot else {
            ilog("No Makefile found in zip")
            throw NSError(domain: "TweakCompiler", code: 2, userInfo: [NSLocalizedDescriptionKey: "No Makefile found. This doesn't appear to be a valid tweak project."])
        }
        
        ilog("Found project root with Makefile")
        
        // Extract project info from control file or Makefile
        var projectName = "Imported Tweak"
        var bundleId = "com.unknown.tweak"
        var targetApp = "com.apple.springboard"
        
        // Try to read control file
        let controlPath = projectRoot.appendingPathComponent("control")
        if FileManager.default.fileExists(atPath: controlPath.path),
           let controlContent = try? String(contentsOf: controlPath, encoding: .utf8) {
            // Parse control file
            for line in controlContent.components(separatedBy: .newlines) {
                if line.hasPrefix("Package:") {
                    bundleId = line.replacingOccurrences(of: "Package:", with: "").trimmingCharacters(in: .whitespaces)
                } else if line.hasPrefix("Name:") {
                    projectName = line.replacingOccurrences(of: "Name:", with: "").trimmingCharacters(in: .whitespaces)
                }
            }
            ilog("Parsed control file: name=\(projectName), bundle=\(bundleId)")
        }
        
        // Try to read plist for target app
        if let plistFiles = try? FileManager.default.contentsOfDirectory(at: projectRoot, includingPropertiesForKeys: nil)
            .filter({ $0.pathExtension == "plist" && $0.lastPathComponent != "entitlements.plist" }),
           let firstPlist = plistFiles.first,
           let plistData = try? Data(contentsOf: firstPlist),
           let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
           let filter = plist["Filter"] as? [String: Any],
           let bundles = filter["Bundles"] as? [String],
           let firstBundle = bundles.first {
            targetApp = firstBundle
            ilog("Found target app: \(targetApp)")
        }
        
        // Create new project directory
        let projectId = UUID()
        let destinationDir = projectsPath.appendingPathComponent(projectId.uuidString)
        
        // Copy project to destination
        try FileManager.default.copyItem(at: projectRoot, to: destinationDir)
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: destinationDir.path)
        
        ilog("Copied to projects directory")
        
        // Create packages directory if it doesn't exist
        let packagesDir = destinationDir.appendingPathComponent("packages")
        if !FileManager.default.fileExists(atPath: packagesDir.path) {
            try FileManager.default.createDirectory(at: packagesDir, withIntermediateDirectories: true)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: packagesDir.path)
        }
        
        // Create project.json
        let project = TweakProject(name: projectName, bundleId: bundleId, targetApp: targetApp, path: destinationDir)
        if let data = try? JSONEncoder().encode(project) {
            let infoPath = destinationDir.appendingPathComponent("project.json")
            FileManager.default.createFile(atPath: infoPath.path, contents: data, attributes: [.protectionKey: FileProtectionType.none])
            ilog("Created project.json")
        }
        
        // Reload projects
        DispatchQueue.main.async {
            self.projects.append(project)
            self.logger.info("Imported project: \(project.name, privacy: .public)")
            self.ilog("✅ Import complete: \(project.name)")
        }
        
        return (project, "Successfully imported \(projectName)")
    }
    
    func deleteProject(_ project: TweakProject) {
        do {
            try FileManager.default.removeItem(at: project.path)
            projects.removeAll { $0.id == project.id }
            logger.info("Deleted project at \(project.path.path, privacy: .public)")
            ilog("Deleted: \(project.name)")
        } catch {
            logger.error("Error deleting project: \(error.localizedDescription, privacy: .public)")
            print("Error deleting project: \(error)")
            ilog("Error deleting: \(error.localizedDescription)")
        }
    }
    
    func openProject(_ project: TweakProject) {
        currentProject = project
        logger.info("Opened project \(project.name, privacy: .public)")
        ilog("Opened: \(project.name)")
    }
}

struct TweakProject: Identifiable, Codable {
    let id: UUID
    let name: String
    let bundleId: String
    let targetApp: String
    let path: URL
    let createdDate: Date
    
    init(name: String, bundleId: String, targetApp: String, path: URL) {
        self.id = UUID()
        self.name = name
        self.bundleId = bundleId
        self.targetApp = targetApp
        self.path = path
        self.createdDate = Date()
    }
    
    init?(from url: URL) {
        let infoPath = url.appendingPathComponent("project.json")
        
        guard let data = try? Data(contentsOf: infoPath),
              let project = try? JSONDecoder().decode(TweakProject.self, from: data) else {
            return nil
        }
        
        self.id = project.id
        self.name = project.name
        self.bundleId = project.bundleId
        self.targetApp = project.targetApp
        self.path = url
        self.createdDate = project.createdDate
    }
    
    func save() {
        let infoPath = path.appendingPathComponent("project.json")
        print("💾 Saving project.json to: \(infoPath)")
        if let data = try? JSONEncoder().encode(self) {
            FileManager.default.createFile(atPath: infoPath.path, contents: data, attributes: nil)
            print("✅ project.json saved successfully")
        } else {
            print("❌ Failed to encode project data")
        }
    }
}
