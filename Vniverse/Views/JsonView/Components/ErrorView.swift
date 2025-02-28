import SwiftUI

struct ErrorView: View {
    let error: JSONErrorWrapper
    @Binding var showErrorAlert: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
            VStack(alignment: .leading) {
                Text("JSON解析失败")
                    .font(.headline)
                Text(error.errorDescription ?? "未知错误")
                    .font(.caption)
            }
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.red.opacity(0.8))
        .cornerRadius(8)
        .onTapGesture {
            showErrorAlert = true
        }
    }
}