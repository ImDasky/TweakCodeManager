import SwiftUI

struct CompileView: View {
    @EnvironmentObject var projectManager: ProjectManager
    @EnvironmentObject var compilationManager: CompilationManager
    @State private var showingProjectPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if projectManager.currentProject == nil {
                    NoProjectSelectedCompileView()
                } else {
                    VStack(spacing: 20) {
                        // Project Info
                        ProjectInfoCard(project: projectManager.currentProject!)
                        
                        // Compilation Controls
                        CompilationControlsView()
                        
                        // Compilation Log
                        CompilationLogView()
                    }
                    .padding()
                }
            }
            .navigationTitle("Compile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if projectManager.currentProject == nil {
                        Button("Select Project") {
                            showingProjectPicker = true
                        }
                    } else {
                        Menu {
                            Button("Select Different Project") {
                                showingProjectPicker = true
                            }
                            
                            Button("Clean Build") {
                                cleanBuild()
                            }
                            
                            Button("Show Build Directory") {
                                // TODO: Open build directory
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingProjectPicker) {
                ProjectPickerView { project in
                    projectManager.openProject(project)
                }
            }
        }
    }
    
    private func cleanBuild() {
        // TODO: Implement clean build
        compilationManager.addLog("Clean build not yet implemented", type: .warning)
    }
}

struct NoProjectSelectedCompileView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hammer.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Project Selected")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Select a project to compile your tweak")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProjectInfoCard: View {
    let project: TweakProject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hammer.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                    
                    Text("Target: \(project.targetApp)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Ready to Compile")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                    
                    Text(project.bundleId)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            HStack {
                InfoItemView(icon: "target", label: "Target App", value: project.targetApp)
                Spacer()
                InfoItemView(icon: "barcode", label: "Bundle ID", value: project.bundleId)
                Spacer()
                InfoItemView(icon: "calendar", label: "Created", value: project.createdDate.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InfoItemView: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
    }
}

struct CompilationControlsView: View {
    @EnvironmentObject var compilationManager: CompilationManager
    @EnvironmentObject var projectManager: ProjectManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Compilation")
                    .font(.headline)
                
                Spacer()
                
                if compilationManager.isCompiling {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: startCompilation) {
                    HStack {
                        Image(systemName: compilationManager.isCompiling ? "stop.circle" : "play.circle")
                        Text(compilationManager.isCompiling ? "Stop" : "Compile")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(compilationManager.isCompiling ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(projectManager.currentProject == nil)
                
                Button("Clear Log") {
                    compilationManager.clearLog()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(8)
            }
            
            if compilationManager.isCompiling {
                ProgressView(value: compilationManager.compilationProgress)
                    .progressViewStyle(LinearProgressViewStyle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func startCompilation() {
        if compilationManager.isCompiling {
            compilationManager.stopCompilation()
        } else if let project = projectManager.currentProject {
            compilationManager.compileProject(project)
        }
    }
}

struct CompilationLogView: View {
    @EnvironmentObject var compilationManager: CompilationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Compilation Log")
                    .font(.headline)
                
                Spacer()
                
                if !compilationManager.compilationLog.isEmpty {
                    Button("Clear") {
                        compilationManager.clearLog()
                    }
                    .font(.caption)
                }
            }
            
            if compilationManager.compilationLog.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "terminal")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No compilation log yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Start a compilation to see the output here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(compilationManager.compilationLog) { entry in
                            LogEntryView(entry: entry)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LogEntryView: View {
    let entry: LogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: entry.type.icon)
                .foregroundColor(entry.type.color)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.message)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(entry.type.color)
                
                Text(entry.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct ProjectPickerView: View {
    @EnvironmentObject var projectManager: ProjectManager
    @Environment(\.dismiss) private var dismiss
    let onProjectSelected: (TweakProject) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(projectManager.projects) { project in
                    Button(action: {
                        onProjectSelected(project)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "hammer.circle.fill")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Target: \(project.targetApp)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Project")
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

#Preview {
    CompileView()
        .environmentObject(ProjectManager())
        .environmentObject(CompilationManager())
}
