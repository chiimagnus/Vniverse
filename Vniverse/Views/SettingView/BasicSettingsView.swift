import SwiftUI

struct BasicSettingsView: View {
    @State private var aiThinkingText: String = UserDefaults.standard.string(forKey: "AIThinkingText") ?? "AI思考回复"
    
    var body: some View {
        Form {
            Section("朗读设置") {
                Text("基本设置项待添加...")
                    .foregroundColor(.secondary)
            }
            Section("阅读设置") {
                TextField("修改AI Chat中的AI名称", text: $aiThinkingText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: aiThinkingText) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "AIThinkingText")
                    }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    BasicSettingsView()
}