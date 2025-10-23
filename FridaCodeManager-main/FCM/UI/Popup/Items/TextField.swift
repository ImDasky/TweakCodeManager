import SwiftUI

struct POTextField: View {
    var title: String
    @Binding var content: String

    var body: some View {
        TextField(title, text: $content)
            .frame(height: 36)
            .padding(.horizontal, 10)
            .background(Color(.systemBackground).opacity(0.7))
            .cornerRadius(10)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .keyboardType(.asciiCapable)
    }
}
