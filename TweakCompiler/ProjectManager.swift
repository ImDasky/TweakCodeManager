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
            export ARCHS = arm64
            export TARGET = iphone:clang:14.5:latest
            
            include $(THEOS)/makefiles/common.mk
            
            TWEAK_NAME = \(name)
            \(name)_FILES = Tweak.x
            \(name)_FRAMEWORKS = UIKit Foundation
            
            include $(THEOS_MAKE_PATH)/tweak.mk
            
            after-install::
                install.exec "sbreload"
            """
            
            let tweak = """
            %hook SpringBoard
            
            - (void)applicationDidFinishLaunching:(id)application {
                %orig;
                NSLog(@"\(name) loaded for \(targetApp)!");
            }
            
            %end
            """
            
            let control = """
            Package: \(bundleId)
            Name: \(name)
            Version: 1.0.0
            Architecture: iphoneos-arm
            Description: Tweak created with TweakCompiler
            Maintainer: Unknown
            Author: Unknown
            Section: Tweaks
            Depends: mobilesubstrate
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
