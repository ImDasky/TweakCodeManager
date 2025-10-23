import SwiftUI

struct ContentView: View {
    @StateObject private var projectManager = ProjectManager()
    @StateObject private var compilationManager = CompilationManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Projects Tab
            ProjectsView()
                .tabItem {
                    Image(systemName: "folder")
                    Text("Projects")
                }
                .tag(0)
            
            // Editor Tab
            EditorView()
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Editor")
                }
                .tag(1)
            
            // Compile Tab
            CompileView()
                .tabItem {
                    Image(systemName: "hammer")
                    Text("Compile")
                }
                .tag(2)
            
            // Install Tab
            InstallView()
                .tabItem {
                    Image(systemName: "arrow.down.circle")
                    Text("Install")
                }
                .tag(3)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(4)
        }
        .environmentObject(projectManager)
        .environmentObject(compilationManager)
    }
}

#Preview {
    ContentView()
}
