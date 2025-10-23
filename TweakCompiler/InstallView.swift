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
    @State private var hasCompiledPackage = false
    @State private var packagePath: URL?
    
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
                HStack(spacing: 12) {
                    Button("Install via Sileo") {
                        installViaSileo()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Install via Zebra") {
                        installViaZebra()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Install via Filza") {
                        installViaFilza()
                    }
                    .buttonStyle(.bordered)
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
    }
    
    private func checkForCompiledPackage() {
        let packagesPath = project.path.appendingPathComponent("packages")
        let debFileName = "\(project.name)_1.0.0_iphoneos-arm.deb"
        let debPath = packagesPath.appendingPathComponent(debFileName)
        
        hasCompiledPackage = FileManager.default.fileExists(atPath: debPath.path)
        packagePath = hasCompiledPackage ? debPath : nil
    }
    
    private func installViaSileo() {
        guard let packagePath = packagePath else { return }
        // TODO: Open in Sileo
    }
    
    private func installViaZebra() {
        guard let packagePath = packagePath else { return }
        // TODO: Open in Zebra
    }
    
    private func installViaFilza() {
        guard let packagePath = packagePath else { return }
        // TODO: Open in Filza
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
