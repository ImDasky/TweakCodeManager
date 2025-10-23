import SwiftUI

struct InstallView: View {
    @EnvironmentObject var projectManager: ProjectManager
    @EnvironmentObject var compilationManager: CompilationManager
    @State private var showingFilePicker = false
    @State private var installedPackages: [InstalledPackage] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if projectManager.currentProject == nil {
                    NoProjectSelectedInstallView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Current Project Section
                            CurrentProjectSection(project: projectManager.currentProject!)
                            
                            // Installation Methods
                            InstallationMethodsSection()
                            
                            // Installed Packages
                            InstalledPackagesSection(packages: installedPackages)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Install")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Select .deb File") {
                            showingFilePicker = true
                        }
                        
                        Button("Refresh Packages") {
                            loadInstalledPackages()
                        }
                        
                        Button("Clear Cache") {
                            // TODO: Clear installation cache
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilePicker) {
                FilePickerView()
            }
            .onAppear {
                loadInstalledPackages()
            }
        }
    }
    
    private func loadInstalledPackages() {
        isLoading = true
        // TODO: Load installed packages from device
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.installedPackages = []
            self.isLoading = false
        }
    }
}

struct NoProjectSelectedInstallView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Project Selected")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Select a project to install your compiled tweak")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CurrentProjectSection: View {
    let project: TweakProject
    @EnvironmentObject var compilationManager: CompilationManager
    @State private var hasCompiledPackage = false
    @State private var packagePath: URL?
    @State private var isInstalling = false
    @State private var installLog: [String] = []
    @State private var showInstallLog = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hammer.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                    
                    Text("Current Project")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if hasCompiledPackage {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Ready to Install")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                        
                        Text(".deb available")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Not Compiled")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                        
                        Text("Compile first")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if hasCompiledPackage {
                if isInstalling {
                    VStack(spacing: 12) {
                        ProgressView("Installing...")
                            .progressViewStyle(CircularProgressViewStyle())
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(installLog, id: \.self) { log in
                                    Text(log)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                } else {
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Button(action: installViaSileo) {
                                Label("Install", systemImage: "arrow.down.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button(action: installViaFilza) {
                                Label("Open in Filza", systemImage: "folder.fill")
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if showInstallLog && !installLog.isEmpty {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 4) {
                                    ForEach(installLog, id: \.self) { log in
                                        Text(log)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .frame(maxHeight: 150)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                    }
                }
            } else {
                Text("Compile your project first to create a .deb package")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            checkForCompiledPackage()
        }
        .onChange(of: compilationManager.lastCompilationResult) { _ in
            checkForCompiledPackage()
        }
    }
    
    private func checkForCompiledPackage() {
        let packagesPath = project.path.appendingPathComponent("packages")
        
        // Look for any .deb file in packages directory
        if let debFiles = try? FileManager.default.contentsOfDirectory(atPath: packagesPath.path).filter({ $0.hasSuffix(".deb") }),
           let latestDeb = debFiles.sorted().last {
            hasCompiledPackage = true
            packagePath = packagesPath.appendingPathComponent(latestDeb)
        } else {
            hasCompiledPackage = false
            packagePath = nil
        }
    }
    
    private func installViaSileo() {
        guard let packagePath = packagePath else { return }
        installDirectly(packagePath)
    }
    
    private func installViaZebra() {
        guard let packagePath = packagePath else { return }
        installDirectly(packagePath)
    }
    
    private func installViaFilza() {
        guard let packagePath = packagePath else { return }
        // Try to open with Filza using file:// URL
        if let url = URL(string: "filza://view\(packagePath.path)") {
            UIApplication.shared.open(url)
        } else {
            // Fallback to direct install
            installDirectly(packagePath)
        }
    }
    
    private func installDirectly(_ debPath: URL) {
        isInstalling = true
        installLog.removeAll()
        showInstallLog = true
        
        installLog.append("📦 Installing \(debPath.lastPathComponent)...")
        installLog.append("📍 Path: \(debPath.path)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Run dpkg -i to install the package
            let (exitCode, output, error) = executeCommand("dpkg", arguments: ["-i", debPath.path])
            
            DispatchQueue.main.async {
                if exitCode == 0 {
                    installLog.append("✅ Installation successful!")
                    installLog.append("")
                    installLog.append("Output:")
                    if !output.isEmpty {
                        output.components(separatedBy: .newlines).forEach { line in
                            if !line.isEmpty {
                                installLog.append(line)
                            }
                        }
                    }
                    
                    // Run uicache to register any apps
                    installLog.append("")
                    installLog.append("🔄 Refreshing icon cache...")
                    let (_, _, _) = executeCommand("uicache", arguments: ["-a"])
                    installLog.append("✅ Done! Respring may be required.")
                } else {
                    installLog.append("❌ Installation failed with exit code \(exitCode)")
                    installLog.append("")
                    installLog.append("Error:")
                    if !error.isEmpty {
                        error.components(separatedBy: .newlines).forEach { line in
                            if !line.isEmpty {
                                installLog.append(line)
                            }
                        }
                    }
                }
                
                isInstalling = false
            }
        }
    }
}

struct InstallationMethodsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Installation Methods")
                .font(.headline)
            
            VStack(spacing: 8) {
                InstallationMethodRow(
                    title: "Sileo",
                    subtitle: "Modern package manager",
                    icon: "s.circle.fill",
                    color: .purple,
                    isAvailable: true
                )
                
                InstallationMethodRow(
                    title: "Zebra",
                    subtitle: "Lightweight package manager",
                    icon: "z.circle.fill",
                    color: .blue,
                    isAvailable: true
                )
                
                InstallationMethodRow(
                    title: "Filza",
                    subtitle: "File manager installation",
                    icon: "folder.circle.fill",
                    color: .orange,
                    isAvailable: true
                )
                
                InstallationMethodRow(
                    title: "Terminal",
                    subtitle: "Command line installation",
                    icon: "terminal.fill",
                    color: .green,
                    isAvailable: false
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InstallationMethodRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isAvailable: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isAvailable ? .primary : .secondary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isAvailable {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Text("Not Available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InstalledPackagesSection: View {
    let packages: [InstalledPackage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Installed Packages")
                    .font(.headline)
                
                Spacer()
                
                Text("\(packages.count) installed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if packages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "package")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No packages installed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Install your first tweak to see it here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(packages) { package in
                        InstalledPackageRow(package: package)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InstalledPackageRow: View {
    let package: InstalledPackage
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "package.fill")
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(package.name)
                    .font(.headline)
                
                Text(package.version)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(package.bundleId)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(package.installDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FilePickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Select .deb File")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Choose a compiled .deb package to install")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Browse Files") {
                    // TODO: Implement file picker
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Install Package")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InstalledPackage: Identifiable {
    let id = UUID()
    let name: String
    let version: String
    let bundleId: String
    let installDate: Date
}

#Preview {
    InstallView()
        .environmentObject(ProjectManager())
        .environmentObject(CompilationManager())
}
