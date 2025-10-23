import SwiftUI

struct EditorView: View {
    @EnvironmentObject var projectManager: ProjectManager
    
    var body: some View {
        NavigationView {
            VStack {
                if projectManager.currentProject == nil {
                    NoProjectSelectedView()
                } else {
                    List {
                        ForEach(projectFiles, id: \.name) { file in
                            NavigationLink(destination: FileEditorView(file: file, projectPath: projectManager.currentProject!.path)) {
                                HStack(spacing: 12) {
                                    Image(systemName: file.type.icon)
                                        .foregroundColor(file.type.color)
                                        .font(.title2)
                                        .frame(width: 40)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(file.name)
                                            .font(.headline)
                                        
                                        Text(file.type.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if let size = fileSize(for: file) {
                                        Text(size)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle(projectManager.currentProject?.name ?? "Files")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if projectManager.currentProject != nil {
                        Button("Close Project") {
                            projectManager.currentProject = nil
                        }
                    }
                }
            }
        }
    }
    
    private var projectFiles: [ProjectFile] {
        guard let project = projectManager.currentProject else { return [] }
        
        return [
            ProjectFile(name: "Makefile", type: .makefile, path: project.path.appendingPathComponent("Makefile")),
            ProjectFile(name: "Tweak.x", type: .source, path: project.path.appendingPathComponent("Tweak.x")),
            ProjectFile(name: "control", type: .control, path: project.path.appendingPathComponent("control")),
            ProjectFile(name: "\(project.name).plist", type: .plist, path: project.path.appendingPathComponent("\(project.name).plist"))
        ].filter { FileManager.default.fileExists(atPath: $0.path.path) }
    }
    
    private func fileSize(for file: ProjectFile) -> String? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: file.path.path),
              let size = attrs[.size] as? Int64 else {
            return nil
        }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// Full-screen file editor
struct FileEditorView: View {
    let file: ProjectFile
    let projectPath: URL
    
    @State private var content = ""
    @State private var isEditing = false
    @State private var fontSize: CGFloat = 14
    @State private var showSaveAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Editor toolbar
            HStack {
                Image(systemName: file.type.icon)
                    .foregroundColor(file.type.color)
                Text(file.name)
                    .font(.system(.body, design: .monospaced))
                
                Spacer()
                
                if isEditing {
                    Text("Edited")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Button("Save") {
                    saveFile()
                }
                .disabled(!isEditing)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Code editor with line numbers
            CodeEditorView(
                content: $content,
                isEditing: $isEditing,
                fontSize: $fontSize
            )
        }
        .navigationTitle(file.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Menu("Font Size") {
                        Button("Small (12pt)") { fontSize = 12 }
                        Button("Medium (14pt)") { fontSize = 14 }
                        Button("Large (16pt)") { fontSize = 16 }
                        Button("Extra Large (18pt)") { fontSize = 18 }
                    }
                } label: {
                    Image(systemName: "textformat.size")
                }
            }
        }
        .onAppear {
            loadFileContent()
        }
        .alert("File Saved", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Changes saved successfully")
        }
    }
    
    private func loadFileContent() {
        if let data = try? Data(contentsOf: file.path),
           let text = String(data: data, encoding: .utf8) {
            content = text
        }
    }
    
    private func saveFile() {
        do {
            try content.write(to: file.path, atomically: true, encoding: .utf8)
            isEditing = false
            showSaveAlert = true
        } catch {
            print("Error saving file: \(error)")
        }
    }
}

struct CodeEditorView: View {
    @Binding var content: String
    @Binding var isEditing: Bool
    @Binding var fontSize: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                HStack(alignment: .top, spacing: 0) {
                    // Line numbers
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(1...max(1, content.components(separatedBy: .newlines).count), id: \.self) { lineNumber in
                            Text("\(lineNumber)")
                                .font(.system(size: fontSize, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(minWidth: 35, alignment: .trailing)
                                .padding(.horizontal, 8)
                        }
                    }
                    .padding(.top, 8)
                    .background(Color(.systemGray6))
                    
                    // Editor content
                    TextEditor(text: $content)
                        .font(.system(size: fontSize, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: content) { _ in
                            isEditing = true
                        }
                        .frame(minWidth: geometry.size.width - 60, minHeight: geometry.size.height, alignment: .topLeading)
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

struct NoProjectSelectedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Project Selected")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Select a project from the Projects tab to view its files")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProjectFile {
    let name: String
    let type: FileType
    let path: URL
    
    enum FileType: String {
        case source = "Source Code"
        case makefile = "Makefile"
        case control = "Control File"
        case plist = "Property List"
        
        var icon: String {
            switch self {
            case .source: return "doc.text.fill"
            case .makefile: return "hammer.fill"
            case .control: return "list.bullet.rectangle"
            case .plist: return "doc.badge.gearshape"
            }
        }
        
        var color: Color {
            switch self {
            case .source: return .blue
            case .makefile: return .orange
            case .control: return .green
            case .plist: return .purple
            }
        }
    }
}

#Preview {
    EditorView()
        .environmentObject(ProjectManager())
}
