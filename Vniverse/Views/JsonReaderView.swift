import SwiftUI

struct JsonReaderView: View {
    let document: Document
    
    // 解析JSON内容
    private var parsedJSON: Any? {
        guard let data = document.content.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: [])
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let json = parsedJSON {
                    Text(String(describing: json))
                        .font(.system(.body, design: .monospaced))
                        .padding()
                } else {
                    Text("无效的JSON格式")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle(document.title)
    }
}
