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
                    
                    ForEach(Array(conversation.messages.enumerated()), id: \.element.id) { index, message in
                        // 获取下一条消息（如果存在）
                        let nextMessage = index + 1 < conversation.messages.count ? conversation.messages[index + 1] : nil
                        
                        // 如果当前消息是思考过程，下一条是助手回复，则使用组合视图
                        if message.role == .thinking && nextMessage?.role == .assistant {
                            // 创建一个自定义的组合视图（思考过程+助手回复）
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.8))
                                        .frame(width: 20, height: 20)
                                    // Image(systemName: "plus")
                                    //     .foregroundColor(.gray)
                                    //     .font(.caption2)
                                    // Image(systemName: "bubble.left.fill")
                                    //     .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                                    //     .frame(width: 20, height: 20)
                                    Text(UserDefaults.standard.string(forKey: "AIThinkingText") ?? "AI思考回复")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // 思考过程折叠部分
                                DisclosureGroup {
                                    Text(message.content)
                                        .textSelection(.enabled)
                                        .foregroundColor(message.role.textColor)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                } label: {
                                    Text("查看思考过程")
                                        .font(.caption)
                                        .foregroundColor(message.role.textColor)
                                }
                                .padding(8)
                                .background(
                                    message.role.bubbleBackground
                                        .cornerRadius(8)
                                )
                                
                                // 助手回复部分
                                Text(nextMessage!.content)
                                    .textSelection(.enabled)
                                    .foregroundColor(nextMessage!.role.textColor)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        nextMessage!.role.bubbleBackground
                                            .cornerRadius(8)
                                    )
                            }
                            .padding(.trailing)
                        } 
                        // 如果是AI助手消息，但前一条是思考过程，则跳过
                        else if message.role == .assistant && index > 0 && conversation.messages[index - 1].role == .thinking {
                            EmptyView()
                        }
                        // 其他类型的消息正常显示
                        else {
                            MessageBubbleView(message: message, nextMessage: nextMessage)
                        }
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
                        content: message.content.stripHTMLTags()
//                        timestamp: message.timestamp
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
