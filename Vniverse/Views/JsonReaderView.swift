import SwiftUI

// 自定义可比较的错误包装类型
struct JSONErrorWrapper: LocalizedError, Equatable {
    let underlyingError: Error
    
    var errorDescription: String? {
        (underlyingError as? LocalizedError)?.errorDescription ?? underlyingError.localizedDescription
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }
}

struct JsonReaderView: View {
    let document: Document
    
    @State private var parsingError: JSONErrorWrapper?
    @State private var formattedJSON = ""
    @State private var showErrorAlert = false
    
    // 使用字符串哈希作为缓存标识
    @State private var contentHash: Int?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if parsingError != nil {
                    errorView
                } else {
                    jsonContentView
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(document.title)
        .onAppear(perform: parseJSON)
        .animation(.easeInOut, value: parsingError)
        .alert("解析错误", isPresented: $showErrorAlert) {
            Button("确定") { }
        } message: {
            Text(parsingError?.errorDescription ?? "未知错误")
        }
    }
    
    private var jsonContentView: some View {
        Text(formattedJSON)
            .font(.system(.callout, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var errorView: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
            VStack(alignment: .leading) {
                Text("JSON解析失败")
                    .font(.headline)
                Text(parsingError?.errorDescription ?? "未知错误")
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
    
    private func parseJSON() {
        let currentHash = document.content.hashValue
        guard currentHash != contentHash else { return }
        contentHash = currentHash
        
        DispatchQueue.global(qos: .userInitiated).async {
            let content = document.content
            var resultText = ""
            var resultError: JSONErrorWrapper?
            
            do {
                guard let data = content.data(using: .utf8) else {
                    throw JSONError.invalidEncoding
                }
                
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                let formattedData = try JSONSerialization.data(
                    withJSONObject: jsonObject,
                    options: [.prettyPrinted, .sortedKeys]
                )
                resultText = String(decoding: formattedData, as: UTF8.self)
            } catch {
                resultText = content
                resultError = JSONErrorWrapper(underlyingError: error)
            }
            
            DispatchQueue.main.async {
                formattedJSON = resultText
                parsingError = resultError
            }
        }
    }
}

enum JSONError: LocalizedError {
    case invalidEncoding
    
    var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            return "非UTF-8编码格式"
        }
    }
}
