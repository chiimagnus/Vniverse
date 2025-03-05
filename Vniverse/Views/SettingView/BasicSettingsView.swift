import SwiftUI

enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "亮色"
        case .dark: return "暗色"
        case .system: return "跟随系统"
        }
    }
}

struct BasicSettingsView: View {
    @State private var aiThinkingText: String = UserDefaults.standard.string(forKey: "AIThinkingText") ?? "AI思考回复"
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @AppStorage("savePositionOnScroll") private var savePositionOnScroll: Bool = false
    
    var body: some View {
        Form {
            Section("主题设置") {
                Picker("主题模式", selection: $appTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("阅读设置") {
                Toggle("实时保存阅读位置", isOn: $savePositionOnScroll)
                
                Text("启用后，滚动时实时保存阅读位置；禁用后，仅在退出文档时保存阅读位置。\n禁用此选项可提高滚动性能。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("朗读设置") {
                Text("基本设置项待添加...")
                    .foregroundColor(.secondary)
            }
            
            Section("其他设置") {
                TextField("修改AI Chat中的AI名称", text: $aiThinkingText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: aiThinkingText) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "AIThinkingText")
                    }
            }
            
            Section("关于Vniverse") {
                NavigationLink {
                    LicenseView()
                } label: {
                    Text("开源条款")
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    BasicSettingsView()
}
