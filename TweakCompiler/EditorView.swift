import SwiftUI

struct EditorView: View {
    @EnvironmentObject var projectManager: ProjectManager
    @State private var selectedFile: ProjectFile?
    @State private var editorContent = ""
    @State private var isEditing = false
    @State private var showingSidebar = true
    @State private var fontSize: CGFloat = 14
    
    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                if projectManager.currentProject == nil {
                    NoProjectSelectedView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // File Sidebar
                    if showingSidebar {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("Files")
                                    .font(.headline)
                                Spacer()
                                Button(action: { showingSidebar.toggle() }) {
                                    Image(systemName: "sidebar.left")
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 0) {
                                    ForEach(projectFiles, id: \.name) { file in
                                        FileRowView(
                                            file: file,
                                            isSelected: selectedFile?.name == file.name
                                        ) {
                                            selectedFile = file
                                            loadFileContent()
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: 240)
                        .background(Color(.systemGray6))
                    }
                    
                    Divider()
                    
                    // Editor Area
                    VStack(spacing: 0) {
                        if !showingSidebar {
                            HStack {
                                Button(action: { showingSidebar.toggle() }) {
                                    HStack {
                                        Image(systemName: "sidebar.left")
                                        Text("Files")
                                    }
                                }
                                .padding()
                                Spacer()
                            }
                            .background(Color(.systemGray6))
                        }
                        
                        if let file = selectedFile {
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
                                .buttonStyle(.bordered)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            
                            // Code editor with line numbers
                            CodeEditorView(
                                content: $editorContent,
                                isEditing: $isEditing,
                                fontSize: $fontSize
                            )
                        } else {
                            VStack(spacing: 20) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                
                                Text("No File Selected")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                
                                Text("Choose a file from the sidebar to start editing")
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(projectManager.currentProject?.name ?? "Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if projectManager.currentProject != nil {
                        Menu {
                            Button(action: { showingSidebar.toggle() }) {
                                Label(showingSidebar ? "Hide Sidebar" : "Show Sidebar", systemImage: "sidebar.left")
                            }
                            
                            Menu("Font Size") {
                                Button("Small (12pt)") { fontSize = 12 }
                                Button("Medium (14pt)") { fontSize = 14 }
                                Button("Large (16pt)") { fontSize = 16 }
                                Button("Extra Large (18pt)") { fontSize = 18 }
                            }
                            
                            Divider()
                            
                            Button("Close Project") {
                                selectedFile = nil
                                projectManager.currentProject = nil
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
        guard let project = projectManager.currentProject else { return [] }
        
        return [
            ProjectFile(name: "Makefile", type: .makefile, path: project.path.appendingPathComponent("Makefile")),
            ProjectFile(name: "Tweak.x", type: .tweak, path: project.path.appendingPathComponent("Tweak.x")),
            ProjectFile(name: "control", type: .control, path: project.path.appendingPathComponent("control")),
            ProjectFile(name: "\(project.name).plist", type: .plist, path: project.path.appendingPathComponent("\(project.name).plist"))
        ]
    }
    
    private func loadFileContent() {
        guard let file = selectedFile else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let content = try String(contentsOf: file.path, encoding: .utf8)
                DispatchQueue.main.async {
                    self.editorContent = content
                    self.isEditing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.editorContent = "Error loading file: \(error.localizedDescription)"
                    self.isEditing = false
                }
            }
        }
    }
    
    private func saveFile() {
        guard let file = selectedFile else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try editorContent.write(to: file.path, atomically: true, encoding: .utf8)
                DispatchQueue.main.async {
                    isEditing = false
                }
            } catch {
                print("Error saving file: \(error)")
            }
        }
    }
}

struct NoProjectSelectedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Project Selected")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Open a project from the Projects tab to start editing")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        .scrollContentBackground(.hidden)
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

#Preview {
    EditorView()
        .environmentObject(ProjectManager())
}
