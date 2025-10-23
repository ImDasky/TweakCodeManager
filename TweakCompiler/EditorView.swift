import SwiftUI
import UniformTypeIdentifiers

struct EditorView: View {
    @EnvironmentObject var projectManager: ProjectManager
    @State private var showingNewFileSheet = false
    @State private var showingNewFolderSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                if projectManager.currentProject == nil {
                    NoProjectSelectedView()
                } else {
                    FileListView(projectPath: projectManager.currentProject!.path)
                }
            }
            .navigationTitle(projectManager.currentProject?.name ?? "Files")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if projectManager.currentProject != nil {
                        Menu {
                            Button(action: { showingNewFileSheet = true }) {
                                Label("New File", systemImage: "doc.badge.plus")
                            }
                            
                            Button(action: { showingNewFolderSheet = true }) {
                                Label("New Folder", systemImage: "folder.badge.plus")
                            }
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewFileSheet) {
                if let project = projectManager.currentProject {
                    NewFileSheet(projectPath: project.path)
                }
            }
            .sheet(isPresented: $showingNewFolderSheet) {
                if let project = projectManager.currentProject {
                    NewFolderSheet(projectPath: project.path)
                                        }
                                    }
                                }
                            }
                        }

// Recursively list all files in project
struct FileListView: View {
    let projectPath: URL
    @State private var fileItems: [FileItem] = []
    @State private var selectedItem: FileItem?
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: FileItem?
    @State private var showingRenameAlert = false
    @State private var itemToRename: FileItem?
    @State private var newName = ""
    
    var body: some View {
        List {
            ForEach(fileItems, id: \.id) { item in
                if item.isDirectory {
                    // Folder row
                    HStack(spacing: 12) {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                            .frame(width: 40)
                        
                        Text(item.name)
                                            .font(.headline)
                                    
                                    Spacer()
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        fileContextMenu(for: item)
                                    }
                                } else {
                    // File row with navigation
                    NavigationLink(destination: FileEditorView(file: item, projectPath: projectPath)) {
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .foregroundColor(item.color)
                                .font(.title2)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                
                                Text(item.relativePath)
                                    .font(.caption)
                                        .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if let size = item.fileSizeString {
                                Text(size)
                                    .font(.caption)
                                        .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .contextMenu {
                        fileContextMenu(for: item)
                    }
                }
            }
        }
        .onAppear {
            loadFiles()
        }
        .alert("Delete \(itemToDelete?.name ?? "Item")?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    deleteItem(item)
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Rename", isPresented: $showingRenameAlert) {
            TextField("New name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                if let item = itemToRename {
                    renameItem(item, to: newName)
                }
            }
        } message: {
            Text("Enter a new name for \(itemToRename?.name ?? "this item")")
        }
    }
    
    @ViewBuilder
    private func fileContextMenu(for item: FileItem) -> some View {
        if !item.isDirectory {
            Button(action: { duplicateFile(item) }) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Button(action: { shareFile(item) }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
            Divider()
        }
        
        Button(action: {
            itemToRename = item
            newName = item.name
            showingRenameAlert = true
        }) {
            Label("Rename", systemImage: "pencil")
        }
        
        Button(role: .destructive, action: {
            itemToDelete = item
            showingDeleteAlert = true
        }) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func loadFiles() {
        fileItems = scanDirectory(at: projectPath, relativeTo: projectPath)
            .sorted { item1, item2 in
                // Sort tweak files first
                let item1IsTweak = item1.isTweakFile
                let item2IsTweak = item2.isTweakFile
                
                if item1IsTweak && !item2IsTweak {
                    return true
                } else if !item1IsTweak && item2IsTweak {
                    return false
                } else {
                    // If both are tweak files or both are not, sort alphabetically
                    return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
                }
            }
    }
    
    private func scanDirectory(at url: URL, relativeTo rootURL: URL) -> [FileItem] {
        var items: [FileItem] = []
        
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return items }
        
        for case let fileURL as URL in enumerator {
            // Skip packages directory
            if fileURL.lastPathComponent == "packages" {
                enumerator.skipDescendants()
                continue
            }
            
            let relativePath = fileURL.path.replacingOccurrences(of: rootURL.path + "/", with: "")
            
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey]) {
                let isDirectory = resourceValues.isDirectory ?? false
                let fileSize = resourceValues.fileSize
                
                let item = FileItem(
                    name: fileURL.lastPathComponent,
                    path: fileURL,
                    relativePath: relativePath,
                    isDirectory: isDirectory,
                    fileSize: fileSize
                )
                items.append(item)
            }
        }
        
        return items
    }
    
    private func deleteItem(_ item: FileItem) {
        do {
            try FileManager.default.removeItem(at: item.path)
            loadFiles()
        } catch {
            print("Error deleting item: \(error)")
        }
    }
    
    private func renameItem(_ item: FileItem, to newName: String) {
        let newPath = item.path.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try FileManager.default.moveItem(at: item.path, to: newPath)
            loadFiles()
        } catch {
            print("Error renaming item: \(error)")
        }
    }
    
    private func duplicateFile(_ item: FileItem) {
        let fileExtension = item.path.pathExtension
        let nameWithoutExt = item.path.deletingPathExtension().lastPathComponent
        let newName = "\(nameWithoutExt) copy.\(fileExtension)"
        let newPath = item.path.deletingLastPathComponent().appendingPathComponent(newName)
        
        do {
            try FileManager.default.copyItem(at: item.path, to: newPath)
            loadFiles()
        } catch {
            print("Error duplicating file: \(error)")
        }
    }
    
    private func shareFile(_ item: FileItem) {
        let activityVC = UIActivityViewController(activityItems: [item.path], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// File item model
struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let relativePath: String
    let isDirectory: Bool
    let fileSize: Int?
    
    // Check if this is a tweak file
    var isTweakFile: Bool {
        let ext = path.pathExtension.lowercased()
        return ["x", "xm", "xi", "xmi"].contains(ext)
    }
    
    var icon: String {
        if isDirectory { return "folder.fill" }
        
        let ext = path.pathExtension.lowercased()
        
        // Tweak files
        if isTweakFile {
            return "doc.text.fill"
        }
        
        switch ext {
        case "m", "mm", "c", "cpp", "h", "hpp", "swift":
            return "doc.text.fill"
        case "plist":
            return "doc.badge.gearshape"
        case "json":
            return "doc.badge.gearshape.fill"
        case "md", "txt":
            return "doc.plaintext"
        case "png", "jpg", "jpeg":
            return "photo"
        default:
            if name == "Makefile" || name == "makefile" {
                return "hammer.fill"
            } else if name == "control" {
                return "list.bullet.rectangle"
            }
            return "doc"
        }
    }
    
    var color: Color {
        if isDirectory { return .blue }
        
        let ext = path.pathExtension.lowercased()
        
        // Tweak files are always blue (main files)
        if isTweakFile {
            return .blue
        }
        
        switch ext {
        case "m", "mm", "c", "cpp":
            return .blue
        case "h", "hpp":
            return .purple
        case "swift":
            return .orange
        case "plist", "json":
            return .green
        default:
            if name == "Makefile" || name == "makefile" {
                return .orange
            } else if name == "control" {
                return .green
            }
            return .gray
        }
    }
    
    var fileSizeString: String? {
        guard let size = fileSize else { return nil }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}

// New file sheet
struct NewFileSheet: View {
    let projectPath: URL
    @State private var fileName = ""
    @State private var selectedTemplate = FileTemplate.empty
    @Environment(\.dismiss) private var dismiss
    
    enum FileTemplate: String, CaseIterable {
        case empty = "Empty File"
        case objcHeader = "Objective-C Header (.h)"
        case objcSource = "Objective-C Source (.m)"
        case tweakFile = "Tweak File (.x)"
        case cSource = "C Source (.c)"
        case cppSource = "C++ Source (.cpp)"
        
        var fileExtension: String {
            switch self {
            case .empty: return "txt"
            case .objcHeader: return "h"
            case .objcSource: return "m"
            case .tweakFile: return "x"
            case .cSource: return "c"
            case .cppSource: return "cpp"
            }
        }
        
        var template: String {
            switch self {
            case .empty:
                return ""
            case .objcHeader:
                return """
                #import <Foundation/Foundation.h>
                
                @interface MyClass : NSObject
                
                @end
                """
            case .objcSource:
                return """
                #import "MyClass.h"
                
                @implementation MyClass
                
                @end
                """
            case .tweakFile:
                return """
                #import <Foundation/Foundation.h>
                #import <UIKit/UIKit.h>
                
                %hook ClassName
                
                // Your hooks here
                
                %end
                """
            case .cSource:
                return """
                #include <stdio.h>
                
                int main() {
                    return 0;
                }
                """
            case .cppSource:
                return """
                #include <iostream>
                
                int main() {
                    return 0;
                }
                """
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("File Information") {
                    TextField("File name", text: $fileName)
                    
                    Picker("Template", selection: $selectedTemplate) {
                        ForEach(FileTemplate.allCases, id: \.self) { template in
                            Text(template.rawValue).tag(template)
                        }
                    }
                }
                
                Section("Preview") {
                    Text(fullFileName)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createFile()
                    }
                    .disabled(fileName.isEmpty)
                }
            }
        }
    }
    
    private var fullFileName: String {
        if fileName.isEmpty {
            return "untitled.\(selectedTemplate.fileExtension)"
        }
        
        // If user already added extension, use it
        if fileName.contains(".") {
            return fileName
        }
        
        return "\(fileName).\(selectedTemplate.fileExtension)"
    }
    
    private func createFile() {
        let filePath = projectPath.appendingPathComponent(fullFileName)
        
        do {
            let content = selectedTemplate.template
            try content.write(to: filePath, atomically: true, encoding: .utf8)
            dismiss()
        } catch {
            print("Error creating file: \(error)")
        }
    }
}

// New folder sheet
struct NewFolderSheet: View {
    let projectPath: URL
    @State private var folderName = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Folder Information") {
                    TextField("Folder name", text: $folderName)
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createFolder()
                    }
                    .disabled(folderName.isEmpty)
                }
            }
        }
    }
    
    private func createFolder() {
        let folderPath = projectPath.appendingPathComponent(folderName)
        
        do {
            try FileManager.default.createDirectory(at: folderPath, withIntermediateDirectories: true)
            dismiss()
        } catch {
            print("Error creating folder: \(error)")
        }
    }
}

// Enhanced file editor with search/replace, undo/redo, and syntax highlighting
struct FileEditorView: View {
    let file: FileItem
    let projectPath: URL
    
    @State private var content = ""
    @State private var originalContent = ""
    @State private var fontSize: CGFloat = 14
    @State private var currentLine: Int = 1
    @State private var showSaveAlert = false
    @State private var showingSearch = false
    @State private var searchText = ""
    @State private var replaceText = ""
    @State private var undoStack: [String] = []
    @State private var redoStack: [String] = []
    @Environment(\.dismiss) private var dismiss
    
    private var isEditing: Bool {
        return content != originalContent
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar (if shown)
            if showingSearch {
                SearchReplaceBar(
                    searchText: $searchText,
                    replaceText: $replaceText,
                    content: $content,
                    onReplace: performReplace,
                    onReplaceAll: performReplaceAll,
                    onClose: { showingSearch = false }
                )
            }
            
            // Editor toolbar
            HStack {
                Image(systemName: file.icon)
                    .foregroundColor(file.color)
                Text(file.name)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(isEditing ? .orange : .primary)
                
                Spacer()
                
                Button(action: pasteReplace) {
                    Image(systemName: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    saveFile()
                }
                .disabled(!isEditing)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Code editor with syntax highlighting
            SyntaxHighlightedEditor(
                content: $content,
                fontSize: $fontSize,
                currentLine: $currentLine,
                fileExtension: file.path.pathExtension,
                onTextChange: { newText in
                    if newText != content {
                        pushUndo()
                        content = newText
                    }
                }
            )
        }
        .navigationTitle(file.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: undo) {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(undoStack.isEmpty)
                    
                    Button(action: redo) {
                        Label("Redo", systemImage: "arrow.uturn.forward")
                    }
                    .disabled(redoStack.isEmpty)
                    
                    Divider()
                    
                    Button(action: { showingSearch.toggle() }) {
                        Label("Search & Replace", systemImage: "magnifyingglass")
                    }
                    
                    Divider()
                    
                    Menu("Font Size") {
                        Button("Small (12pt)") { fontSize = 12 }
                        Button("Medium (14pt)") { fontSize = 14 }
                        Button("Large (16pt)") { fontSize = 16 }
                        Button("Extra Large (18pt)") { fontSize = 18 }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
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
            originalContent = text
        }
    }
    
    private func saveFile() {
        do {
            try content.write(to: file.path, atomically: true, encoding: .utf8)
            originalContent = content
            showSaveAlert = true
        } catch {
            print("Error saving file: \(error)")
        }
    }
    
    private func pasteReplace() {
        if let clipboardText = UIPasteboard.general.string {
            pushUndo()
            content = clipboardText
        }
    }
    
    private func pushUndo() {
        undoStack.append(originalContent)
        redoStack.removeAll()
    }
    
    private func undo() {
        guard !undoStack.isEmpty else { return }
        redoStack.append(content)
        content = undoStack.removeLast()
    }
    
    private func redo() {
        guard !redoStack.isEmpty else { return }
        undoStack.append(content)
        content = redoStack.removeLast()
    }
    
    private func performReplace() {
        guard !searchText.isEmpty else { return }
        if let range = content.range(of: searchText) {
            pushUndo()
            content.replaceSubrange(range, with: replaceText)
        }
    }
    
    private func performReplaceAll() {
        guard !searchText.isEmpty else { return }
        pushUndo()
        content = content.replacingOccurrences(of: searchText, with: replaceText)
    }
}

// Search and replace bar
struct SearchReplaceBar: View {
    @Binding var searchText: String
    @Binding var replaceText: String
    @Binding var content: String
    let onReplace: () -> Void
    let onReplaceAll: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.secondary)
                TextField("Replace", text: $replaceText)
                    .textFieldStyle(.roundedBorder)
                
                Button("Replace") { onReplace() }
                    .buttonStyle(.bordered)
                    .disabled(searchText.isEmpty)
                
                Button("All") { onReplaceAll() }
                    .buttonStyle(.bordered)
                    .disabled(searchText.isEmpty)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// Syntax highlighted editor with line indicator
struct SyntaxHighlightedEditor: View {
    @Binding var content: String
    @Binding var fontSize: CGFloat
    @Binding var currentLine: Int
    let fileExtension: String
    let onTextChange: (String) -> Void
    
    var body: some View {
        SyntaxHighlightedTextEditorWithLineNumbers(
            text: $content,
            fontSize: fontSize,
            fileExtension: fileExtension,
            onTextChange: onTextChange,
            currentLine: $currentLine
        )
        .background(Color(.systemBackground))
    }
}

// Custom text editor with syntax highlighting and line indicator
struct SyntaxHighlightedTextEditorWithLineNumbers: UIViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat
    let fileExtension: String
    let onTextChange: (String) -> Void
    @Binding var currentLine: Int
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.spellCheckingType = .no
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.smartInsertDeleteType = .no
        textView.backgroundColor = .systemBackground
        textView.textColor = .label
        textView.text = text
        
        // Create keyboard toolbar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let lineLabel = UILabel()
        lineLabel.text = "Line: 1"
        lineLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        lineLabel.textColor = .secondaryLabel
        lineLabel.tag = 999 // Tag to find it later
        
        let labelItem = UIBarButtonItem(customView: lineLabel)
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.dismissKeyboard))
        
        toolbar.items = [labelItem, flexSpace, doneButton]
        textView.inputAccessoryView = toolbar
        
        // Store reference to text view in coordinator
        context.coordinator.textView = textView
        
        // Apply syntax highlighting
        context.coordinator.applySyntaxHighlighting(to: textView, fileExtension: fileExtension)
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            let selectedRange = textView.selectedRange
            textView.text = text
            
            // Reapply syntax highlighting
            context.coordinator.applySyntaxHighlighting(to: textView, fileExtension: fileExtension)
            
            // Restore cursor position
            textView.selectedRange = selectedRange
        }
        
        textView.font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        // Update current line display
        context.coordinator.updateCurrentLine()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, currentLine: $currentLine, onTextChange: onTextChange)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        @Binding var currentLine: Int
        let onTextChange: (String) -> Void
        weak var textView: UITextView?
        
        init(text: Binding<String>, currentLine: Binding<Int>, onTextChange: @escaping (String) -> Void) {
            _text = text
            _currentLine = currentLine
            self.onTextChange = onTextChange
        }
        
        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
            onTextChange(textView.text)
            applySyntaxHighlighting(to: textView, fileExtension: "x")
            updateCurrentLine()
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            updateCurrentLine()
        }
        
        @objc func dismissKeyboard() {
            textView?.resignFirstResponder()
        }
        
        func updateCurrentLine() {
            guard let textView = textView else { return }
            
            // Calculate current line number
            let cursorPosition = textView.selectedRange.location
            let textBeforeCursor = (textView.text as NSString).substring(to: cursorPosition)
            let lineNumber = textBeforeCursor.components(separatedBy: .newlines).count
            
            currentLine = lineNumber
            
            // Update toolbar label
            if let toolbar = textView.inputAccessoryView as? UIToolbar,
               let labelItem = toolbar.items?.first,
               let label = labelItem.customView as? UILabel {
                label.text = "Line: \(lineNumber)"
            }
        }
        
        func applySyntaxHighlighting(to textView: UITextView, fileExtension: String) {
            let text = textView.text ?? ""
            let attributedString = NSMutableAttributedString(string: text)
            
            // Base attributes
            let baseFont = UIFont.monospacedSystemFont(ofSize: textView.font?.pointSize ?? 14, weight: .regular)
            attributedString.addAttribute(.font, value: baseFont, range: NSRange(location: 0, length: text.count))
            attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: text.count))
            
            // Syntax highlighting patterns
            highlightPattern(in: attributedString, pattern: "//.*", color: .systemGreen) // Comments
            highlightPattern(in: attributedString, pattern: "/\\*[^*]*\\*+(?:[^/*][^*]*\\*+)*/", color: .systemGreen) // Multi-line comments
            highlightPattern(in: attributedString, pattern: "#import\\s+[<\"].*?[>\"]", color: .systemPurple) // Imports
            highlightPattern(in: attributedString, pattern: "#include\\s+[<\"].*?[>\"]", color: .systemPurple) // Includes
            highlightPattern(in: attributedString, pattern: "@\".*?\"", color: .systemRed) // Obj-C strings
            highlightPattern(in: attributedString, pattern: "\".*?\"", color: .systemRed) // Strings
            highlightPattern(in: attributedString, pattern: "'.'", color: .systemRed) // Characters
            highlightPattern(in: attributedString, pattern: "\\b(if|else|for|while|do|switch|case|break|continue|return|void|int|float|double|char|long|short|unsigned|signed|const|static|extern|typedef|struct|enum|union|class|interface|implementation|protocol|property|synthesize|dynamic|IBOutlet|IBAction|NS_ENUM|NS_OPTIONS)\\b", color: .systemPink) // Keywords
            highlightPattern(in: attributedString, pattern: "\\b(NSString|NSArray|NSDictionary|NSObject|UIView|UIViewController|UIButton|UILabel|NSInteger|NSUInteger|CGFloat|BOOL|YES|NO|nil|NULL|true|false|self|super)\\b", color: .systemTeal) // Types
            highlightPattern(in: attributedString, pattern: "@\\w+", color: .systemOrange) // Obj-C directives
            highlightPattern(in: attributedString, pattern: "%\\w+", color: .systemIndigo) // Logos directives
            highlightPattern(in: attributedString, pattern: "\\b\\d+\\b", color: .systemBlue) // Numbers
            
            textView.attributedText = attributedString
        }
        
        private func highlightPattern(in attributedString: NSMutableAttributedString, pattern: String, color: UIColor) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
            let range = NSRange(location: 0, length: attributedString.length)
            let matches = regex.matches(in: attributedString.string, options: [], range: range)
            
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        }
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

#Preview {
    EditorView()
        .environmentObject(ProjectManager())
}
