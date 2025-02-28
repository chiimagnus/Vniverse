import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct JsonReaderView: View {
    let document: Document
    
    @State private var parsedMessages: [Conversation] = []
    @State private var parsingError: JSONErrorWrapper?
    @State private var expandedRawJSON = false
    @State private var formattedJSON = ""
    @State private var showErrorAlert = false
    
    // 使用字符串哈希作为缓存标识
    @State private var contentHash: Int?
    
    // 时间格式化
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if parsingError != nil {
                    ErrorView(error: parsingError!, showErrorAlert: $showErrorAlert)
                } else {
                    conversationListView
                }
                
                rawJSONToggle
            }
            .padding()
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
    
    // MARK: - 子视图
    
    // 对话列表视图
    private var conversationListView: some View {
        LazyVStack(spacing: 20) {
            ForEach(parsedMessages) { conversation in
                VStack(alignment: .leading, spacing: 8) {
                    Text("对话 #\(conversation.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(conversation.messages) { message in
                        MessageBubbleView(message: message)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        #if os(iOS)
                        .fill(Color(UIColor.systemBackground))
                        #elseif os(macOS)
                        .fill(Color(NSColor.textBackgroundColor))
                        #endif
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
            }
        }
    }
    
    // 原始JSON切换
    private var rawJSONToggle: some View {
        DisclosureGroup(isExpanded: $expandedRawJSON) {
            Text(formattedJSON)
                .font(.system(.footnote, design: .monospaced))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        } label: {
            Text("显示原始JSON")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 数据处理
    
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
                
                // 解析对话
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let rawData = try decoder.decode(RawConversation.self, from: data)
                
                // 按对话ID分组
                var conversations: [String: Conversation] = [:]
                
                for message in rawData.messages {
                    let components = message.id.components(separatedBy: "-")
                    guard components.count >= 2 else { continue }
                    let conversationID = components.last!
                    
                    let role = MessageRole(rawValue: message.role) ?? .unknown
                    let newMessage = Message(
                        id: message.id,
                        role: role,
                        content: message.content.stripHTMLTags(),
                        timestamp: message.timestamp
                    )
                    
                    if var existing = conversations[conversationID] {
                        existing.messages.append(newMessage)
                        conversations[conversationID] = existing
                    } else {
                        conversations[conversationID] = Conversation(
                            id: conversationID,
                            messages: [newMessage]
                        )
                    }
                }
                
                parsedMessages = conversations.values.sorted { $0.id < $1.id }
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
