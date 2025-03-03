import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 基本设置
            NavigationStack {
                BasicSettingsView()
            }
            .tabItem {
                Label("基本设置", systemImage: "gear")
            }
            .tag(0)
            
            // GPT-SoVITS设置
            NavigationStack {
                GPTSovitsSettingView()
            }
            .tabItem {
                Label("AI语音设置", systemImage: "waveform")
            }
            .tag(1)
        }
        .frame(width: 600, height: 400)
        .padding()
    }
}



#Preview {
    SettingsView()
}