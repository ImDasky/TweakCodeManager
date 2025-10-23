import SwiftUI

struct ProjectDetailView: View {
    let project: TweakProject
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFile: ProjectFile?
    @State private var showingFileBrowser = true
    
    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                // File Browser Sidebar
                if showingFileBrowser {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Files")
                                .font(.headline)
                                .padding(.horizontal)
                            Spacer()
                            Button(action: { showingFileBrowser.toggle() }) {
                                Image(systemName: "sidebar.left")
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(projectFiles, id: \.name) { file in
                                    FileRowView(
                                        file: file,
                                        isSelected: selectedFile?.name == file.name
                                    ) {
                                        selectedFile = file
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: 250)
                    .background(Color(.systemGray6))
                }
                
                // Main Content
                VStack(spacing: 0) {
                    if !showingFileBrowser {
                        Button(action: { showingFileBrowser.toggle() }) {
                            HStack {
                                Image(systemName: "sidebar.left")
                                Text("Show Files")
                            }
                            .padding()
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                    }
                    
                    if let file = selectedFile {
                        FileContentView(file: file, project: project)
                    } else {
                        ProjectOverviewView(project: project)
                    }
                }
            }
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingFileBrowser.toggle() }) {
                            Image(systemName: showingFileBrowser ? "sidebar.left" : "sidebar.right")
                        }
                        
                        Menu {
                            Button("Compile Project") {
                                // TODO: Implement compilation
                            }
                            
                            Button("Open in Files") {
                                // TODO: Open in Files app
                            }
                            
                            Button("Export Project") {
                                // TODO: Export project
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
    }
    
    private var projectFiles: [ProjectFile] {
        [
            ProjectFile(name: "Makefile", type: .makefile, path: project.path.appendingPathComponent("Makefile")),
            ProjectFile(name: "Tweak.x", type: .tweak, path: project.path.appendingPathComponent("Tweak.x")),
            ProjectFile(name: "control", type: .control, path: project.path.appendingPathComponent("control")),
            ProjectFile(name: "\(project.name).plist", type: .plist, path: project.path.appendingPathComponent("\(project.name).plist"))
        ]
    }
}

struct ProjectFile {
    let name: String
    let type: FileType
    let path: URL
    
    enum FileType {
        case makefile
        case tweak
        case control
        case plist
        
        var icon: String {
            switch self {
            case .makefile: return "doc.text"
            case .tweak: return "hammer.circle"
            case .control: return "gear"
            case .plist: return "list.bullet"
            }
        }
        
        var color: Color {
            switch self {
            case .makefile: return .orange
            case .tweak: return .blue
            case .control: return .green
            case .plist: return .purple
            }
        }
    }
}

struct FileRowView: View {
    let file: ProjectFile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: file.type.icon)
                    .foregroundColor(file.type.color)
                    .frame(width: 20)
                
                Text(file.name)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FileContentView: View {
    let file: ProjectFile
    let project: TweakProject
    @State private var content = ""
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: file.type.icon)
                    .foregroundColor(file.type.color)
                Text(file.name)
                    .font(.headline)
                Spacer()
                Button("Edit") {
                    // TODO: Open editor
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.systemGray6))
            
            if isLoading {
                ProgressView("Loading file...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .onAppear {
            loadFileContent()
        }
    }
    
    private func loadFileContent() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let content = try String(contentsOf: file.path, encoding: .utf8)
                DispatchQueue.main.async {
                    self.content = content
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.content = "Error loading file: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

struct ProjectOverviewView: View {
    let project: TweakProject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Project Information")
                    .font(.title2)
                    .fontWeight(.bold)
                
                InfoRowView(label: "Name", value: project.name)
                InfoRowView(label: "Bundle ID", value: project.bundleId)
                InfoRowView(label: "Target App", value: project.targetApp)
                InfoRowView(label: "Created", value: project.createdDate.formatted(date: .abbreviated, time: .shortened))
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Actions")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 8) {
                    ActionButtonView(
                        title: "Compile Project",
                        subtitle: "Build the tweak package",
                        icon: "hammer.circle",
                        color: .blue
                    ) {
                        // TODO: Implement compilation
                    }
                    
                    ActionButtonView(
                        title: "Open in Files",
                        subtitle: "Browse project files",
                        icon: "folder",
                        color: .green
                    ) {
                        // TODO: Open in Files app
                    }
                    
                    ActionButtonView(
                        title: "Install Package",
                        subtitle: "Install compiled .deb",
                        icon: "arrow.down.circle",
                        color: .orange
                    ) {
                        // TODO: Implement installation
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct InfoRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.body, design: .monospaced))
            Spacer()
        }
    }
}

struct ActionButtonView: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
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
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProjectDetailView(project: TweakProject(
        name: "MyTweak",
        bundleId: "com.example.mytweak",
        targetApp: "SpringBoard",
        path: URL(fileURLWithPath: "/tmp")
    ))
}
