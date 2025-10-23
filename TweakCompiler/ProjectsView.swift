import SwiftUI
import UniformTypeIdentifiers

struct ProjectsView: View {
    @EnvironmentObject var projectManager: ProjectManager
    @Binding var selectedTab: Int
    @State private var showingNewProject = false
    @State private var newName = ""
    @State private var newBundleId = ""
    @State private var newTargetApp = "com.apple.springboard"
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingImportPicker = false
    
	var body: some View {
		NavigationView {
			content
			.navigationTitle("Tweak Projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingNewProject = true
                        } label: {
                            Label("New Project", systemImage: "plus.circle")
                        }
                        
                        Button {
                            showingImportPicker = true
                        } label: {
                            Label("Import from Zip", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewProject) {
                NavigationView {
                    Form {
                        Section(header: Text("Project Info")) {
                            TextField("Name", text: $newName)
                            TextField("Bundle ID (e.g. com.example.tweak)", text: $newBundleId)
                            TextField("Target App Bundle ID", text: $newTargetApp)
                        }
                    }
                    .navigationTitle("New Project")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingNewProject = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Create") {
                                create()
                            }
                            .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newBundleId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newTargetApp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
        }
        .alert("Project Creation Failed", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingImportPicker) {
            DocumentPicker(allowedTypes: ["public.zip-archive"]) { url in
                importProject(from: url)
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if projectManager.isLoading {
            ProgressView("Loading projects...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if projectManager.projects.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("No Tweak Projects")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("No projects available")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button {
                    showingNewProject = true
                } label: {
                    Label("New Project", systemImage: "plus")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(projectManager.projects) { project in
                    ProjectRowView(project: project)
                        .onTapGesture {
                            projectManager.openProject(project)
                            selectedTab = 1 // Switch to Editor tab
                        }
                }
                .onDelete(perform: deleteProjects)
            }
        }
    }
    
    private func deleteProjects(offsets: IndexSet) {
        for index in offsets {
            let project = projectManager.projects[index]
            projectManager.deleteProject(project)
        }
    }
    
    private func importProject(from url: URL) {
        showingImportPicker = false
        
        do {
            let result = try projectManager.importProject(from: url)
            if let project = result.project {
                projectManager.openProject(project)
                selectedTab = 1 // Switch to Editor tab
            }
        } catch {
            errorMessage = "Failed to import project: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    private func create() {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBundle = newBundleId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTarget = newTargetApp.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedBundle.isEmpty, !trimmedTarget.isEmpty else { return }
        if let project = projectManager.createProject(name: trimmedName, bundleId: trimmedBundle, targetApp: trimmedTarget) {
            projectManager.openProject(project)
            projectManager.loadProjects()
            newName = ""
            newBundleId = ""
            newTargetApp = "com.apple.springboard"
            showingNewProject = false
            selectedTab = 1 // Switch to Editor tab
        } else {
            errorMessage = "Could not create files in Application Support/TweakProjects. Check the Activity Log below."
            showErrorAlert = true
        }
    }
}

struct ProjectRowView: View {
    let project: TweakProject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "hammer.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Target: \(project.targetApp)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(project.bundleId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(project.createdDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Label("Bundle ID", systemImage: "barcode")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("Created", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// UIKit Document Picker wrapper
struct DocumentPicker: UIViewControllerRepresentable {
    let allowedTypes: [String]
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.zip])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

#Preview {
    ProjectsView(selectedTab: .constant(0))
        .environmentObject(ProjectManager())
}
