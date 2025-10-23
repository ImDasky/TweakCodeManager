import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager()
    @State private var showingTheosSetup = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            List {
                // Theos Configuration
                Section("Theos Configuration") {
                    SettingsRowView(
                        icon: "hammer.circle.fill",
                        title: "Theos Installation",
                        subtitle: settings.theosPath.isEmpty ? "Not configured" : settings.theosPath,
                        color: .blue
                    ) {
                        showingTheosSetup = true
                    }
                    
                    SettingsRowView(
                        icon: "gear.circle.fill",
                        title: "SDK Path",
                        subtitle: settings.sdkPath.isEmpty ? "Auto-detect" : settings.sdkPath,
                        color: .green
                    ) {
                        // TODO: SDK configuration
                    }
                }
                
                // Compilation Settings
                Section("Compilation") {
                    Toggle("Auto-save before compile", isOn: $settings.autoSaveBeforeCompile)
                    
                    Toggle("Show compilation progress", isOn: $settings.showCompilationProgress)
                    
                    Toggle("Clean build by default", isOn: $settings.cleanBuildByDefault)
                    
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Compilation Threads")
                            Text("Number of parallel compilation threads")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Stepper("\(settings.compilationThreads)", value: $settings.compilationThreads, in: 1...8)
                    }
                }
                
                // Editor Settings
                Section("Editor") {
                    Toggle("Syntax highlighting", isOn: $settings.syntaxHighlighting)
                    
                    Toggle("Line numbers", isOn: $settings.showLineNumbers)
                    
                    Toggle("Auto-indent", isOn: $settings.autoIndent)
                    
                    Toggle("Word wrap", isOn: $settings.wordWrap)
                    
                    HStack {
                        Image(systemName: "textformat.size")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text("Font Size")
                            Text("Editor font size")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Stepper("\(Int(settings.fontSize))", value: $settings.fontSize, in: 10...24)
                    }
                }
                
                // Package Management
                Section("Package Management") {
                    SettingsRowView(
                        icon: "arrow.down.circle.fill",
                        title: "Default Package Manager",
                        subtitle: settings.defaultPackageManager.rawValue,
                        color: .blue
                    ) {
                        // TODO: Package manager selection
                    }
                    
                    Toggle("Auto-open after install", isOn: $settings.autoOpenAfterInstall)
                    
                    Toggle("Keep .deb files", isOn: $settings.keepDebFiles)
                }
                
                // Advanced Settings
                Section("Advanced") {
                    SettingsRowView(
                        icon: "folder.fill",
                        title: "Projects Directory",
                        subtitle: settings.projectsDirectory.path,
                        color: .gray
                    ) {
                        // TODO: Change projects directory
                    }
                    
                    SettingsRowView(
                        icon: "trash.fill",
                        title: "Clear Cache",
                        subtitle: "Remove temporary files",
                        color: .red
                    ) {
                        clearCache()
                    }
                    
                    SettingsRowView(
                        icon: "arrow.clockwise",
                        title: "Reset Settings",
                        subtitle: "Restore default configuration",
                        color: .orange
                    ) {
                        resetSettings()
                    }
                }
                
                // About Section
                Section("About") {
                    SettingsRowView(
                        icon: "info.circle.fill",
                        title: "About TweakCompiler",
                        subtitle: "Version 1.0.0",
                        color: .blue
                    ) {
                        showingAbout = true
                    }
                    
                    SettingsRowView(
                        icon: "questionmark.circle.fill",
                        title: "Help & Documentation",
                        subtitle: "Learn how to use TweakCompiler",
                        color: .green
                    ) {
                        // TODO: Open documentation
                    }
                    
                    SettingsRowView(
                        icon: "envelope.fill",
                        title: "Contact Support",
                        subtitle: "Get help with issues",
                        color: .purple
                    ) {
                        // TODO: Contact support
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingTheosSetup) {
                TheosSetupView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
    
    private func clearCache() {
        // TODO: Implement cache clearing
    }
    
    private func resetSettings() {
        settings.resetToDefaults()
    }
}

struct SettingsRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TheosSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager()
    @State private var theosPath = ""
    @State private var isInstalling = false
    @State private var installationProgress = 0.0
    @State private var installationLog: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "hammer.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Theos Setup")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Configure Theos for tweak compilation")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Theos Installation Path")
                        .font(.headline)
                    
                    HStack {
                        TextField("/var/theos", text: $theosPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Browse") {
                            // TODO: Implement path picker
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text("Theos will be installed at this location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if isInstalling {
                    VStack(spacing: 12) {
                        ProgressView(value: installationProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text("Installing Theos...")
                            .font(.headline)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(installationLog, id: \.self) { log in
                                    Text(log)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                } else {
                    VStack(spacing: 8) {
                        Button("Install Theos") {
                            installTheos()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(theosPath.isEmpty)
                        
                        Button("Use Existing Installation") {
                            // TODO: Use existing installation
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Theos Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(isInstalling)
                }
            }
        }
        .onAppear {
            theosPath = settings.theosPath
        }
    }
    
    private func installTheos() {
        isInstalling = true
        installationProgress = 0.0
        installationLog.removeAll()
        
        // TODO: Implement actual Theos installation
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 1...10 {
                DispatchQueue.main.async {
                    self.installationProgress = Double(i) / 10.0
                    self.installationLog.append("Step \(i): Installing Theos components...")
                }
                Thread.sleep(forTimeInterval: 0.5)
            }
            
            DispatchQueue.main.async {
                self.isInstalling = false
                self.settings.theosPath = self.theosPath
                self.dismiss()
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "hammer.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("TweakCompiler")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 12) {
                    Text("A powerful iOS tweak development environment")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("Create, compile, and install iOS tweaks with ease. Built with SwiftUI and designed for modern iOS development workflows.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 8) {
                    Text("Features")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        FeatureRowView(feature: "Theos Integration")
                        FeatureRowView(feature: "Syntax Highlighting")
                        FeatureRowView(feature: "Real-time Compilation")
                        FeatureRowView(feature: "Package Management")
                        FeatureRowView(feature: "Project Templates")
                    }
                }
                
                VStack(spacing: 8) {
                    Text("Credits")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        CreditRowView(name: "Theos", description: "iOS development framework")
                        CreditRowView(name: "SwiftUI", description: "User interface framework")
                        CreditRowView(name: "FridaCodeManager", description: "UI inspiration")
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRowView: View {
    let feature: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(feature)
                .font(.subheadline)
        }
    }
}

struct CreditRowView: View {
    let name: String
    let description: String
    
    var body: some View {
        HStack {
            Text(name)
                .fontWeight(.medium)
            Text("- \(description)")
                .foregroundColor(.secondary)
        }
        .font(.caption)
    }
}

class SettingsManager: ObservableObject {
    private let defaults = UserDefaults.standard
    
    @Published var theosPath = "/var/theos" {
        didSet { defaults.set(theosPath, forKey: "theosPath") }
    }
    @Published var sdkPath = "/var/theos/sdks" {
        didSet { defaults.set(sdkPath, forKey: "sdkPath") }
    }
    @Published var autoSaveBeforeCompile = true {
        didSet { defaults.set(autoSaveBeforeCompile, forKey: "autoSaveBeforeCompile") }
    }
    @Published var showCompilationProgress = true {
        didSet { defaults.set(showCompilationProgress, forKey: "showCompilationProgress") }
    }
    @Published var cleanBuildByDefault = false {
        didSet { defaults.set(cleanBuildByDefault, forKey: "cleanBuildByDefault") }
    }
    @Published var compilationThreads = 4 {
        didSet { defaults.set(compilationThreads, forKey: "compilationThreads") }
    }
    @Published var syntaxHighlighting = true {
        didSet { defaults.set(syntaxHighlighting, forKey: "syntaxHighlighting") }
    }
    @Published var showLineNumbers = true {
        didSet { defaults.set(showLineNumbers, forKey: "showLineNumbers") }
    }
    @Published var autoIndent = true {
        didSet { defaults.set(autoIndent, forKey: "autoIndent") }
    }
    @Published var wordWrap = true {
        didSet { defaults.set(wordWrap, forKey: "wordWrap") }
    }
    @Published var fontSize: Double = 14 {
        didSet { defaults.set(fontSize, forKey: "fontSize") }
    }
    @Published var defaultPackageManager = PackageManager.sileo {
        didSet { defaults.set(defaultPackageManager.rawValue, forKey: "defaultPackageManager") }
    }
    @Published var autoOpenAfterInstall = true {
        didSet { defaults.set(autoOpenAfterInstall, forKey: "autoOpenAfterInstall") }
    }
    @Published var keepDebFiles = true {
        didSet { defaults.set(keepDebFiles, forKey: "keepDebFiles") }
    }
    @Published var projectsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("TweakProjects") {
        didSet { defaults.set(projectsDirectory.path, forKey: "projectsDirectory") }
    }
    
    enum PackageManager: String, CaseIterable {
        case sileo = "Sileo"
        case zebra = "Zebra"
        case filza = "Filza"
    }
    
    init() {
        // Load saved settings
        self.theosPath = defaults.string(forKey: "theosPath") ?? "/var/theos"
        self.sdkPath = defaults.string(forKey: "sdkPath") ?? "/var/theos/sdks"
        self.autoSaveBeforeCompile = defaults.object(forKey: "autoSaveBeforeCompile") as? Bool ?? true
        self.showCompilationProgress = defaults.object(forKey: "showCompilationProgress") as? Bool ?? true
        self.cleanBuildByDefault = defaults.object(forKey: "cleanBuildByDefault") as? Bool ?? false
        self.compilationThreads = defaults.integer(forKey: "compilationThreads") != 0 ? defaults.integer(forKey: "compilationThreads") : 4
        self.syntaxHighlighting = defaults.object(forKey: "syntaxHighlighting") as? Bool ?? true
        self.showLineNumbers = defaults.object(forKey: "showLineNumbers") as? Bool ?? true
        self.autoIndent = defaults.object(forKey: "autoIndent") as? Bool ?? true
        self.wordWrap = defaults.object(forKey: "wordWrap") as? Bool ?? true
        self.fontSize = defaults.double(forKey: "fontSize") != 0 ? defaults.double(forKey: "fontSize") : 14
        
        if let pmString = defaults.string(forKey: "defaultPackageManager"),
           let pm = PackageManager(rawValue: pmString) {
            self.defaultPackageManager = pm
        }
        
        self.autoOpenAfterInstall = defaults.object(forKey: "autoOpenAfterInstall") as? Bool ?? true
        self.keepDebFiles = defaults.object(forKey: "keepDebFiles") as? Bool ?? true
        
        if let projectsPath = defaults.string(forKey: "projectsDirectory") {
            self.projectsDirectory = URL(fileURLWithPath: projectsPath)
        }
    }
    
    func resetToDefaults() {
        theosPath = "/var/theos"
        sdkPath = "/var/theos/sdks"
        autoSaveBeforeCompile = true
        showCompilationProgress = true
        cleanBuildByDefault = false
        compilationThreads = 4
        syntaxHighlighting = true
        showLineNumbers = true
        autoIndent = true
        wordWrap = true
        fontSize = 14
        defaultPackageManager = .sileo
        autoOpenAfterInstall = true
        keepDebFiles = true
    }
}

#Preview {
    SettingsView()
}
