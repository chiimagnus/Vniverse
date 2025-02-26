import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

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
                    errorView
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
                        messageBubble(for: message)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color(UIColor.systemBackground))
                            #if os(iOS)
                            .fill(Color(UIColor.systemBackground))
                            #elseif os(macOS)
                            .fill(Color(NSColor.textBackgroundColor)) // macOS系统背景色
                            #endif
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
            }
        }
    }
    
    // 消息气泡
    @ViewBuilder
    private func messageBubble(for message: Message) -> some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    roleIcon(message.role)
                    Text(message.role.displayName)
                        .font(.caption)
                        .foregroundColor(message.role.textColor)
                }
                
                Text(message.content)
                    .textSelection(.enabled)
                    .foregroundColor(message.role.textColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        message.role.bubbleBackground
                            .cornerRadius(8)
                    )
                
                if let time = message.timestamp {
                    Text(timeFormatter.string(from: time))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if message.role != .user {
                Spacer()
            }
        }
    }
    
    // 角色图标
    private func roleIcon(_ role: MessageRole) -> some View {
        Image(systemName: role.iconName)
            .foregroundColor(role.iconColor)
            .frame(width: 20, height: 20)
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
    
    // 错误视图
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

// MARK: - 数据模型
struct Conversation: Identifiable {
    let id: String
    var messages: [Message]
}

struct Message: Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date?
}

enum MessageRole: String {
    case user
    case assistant
    case thinking
    case unknown
    
    var displayName: String {
        switch self {
        case .user: return "用户"
        case .assistant: return "助手"
        case .thinking: return "思考中"
        case .unknown: return "未知"
        }
    }
    
    var iconName: String {
        switch self {
        case .user: return "person.circle.fill"
        case .assistant: return "bubble.left.fill"
        case .thinking: return "brain.head.profile"
        case .unknown: return "questionmark.circle"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .user: return .blue
        case .assistant: return .green
        case .thinking: return .purple
        case .unknown: return .gray
        }
    }
    
    var bubbleBackground: some View {
        Group {
            switch self {
            case .user:
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .assistant:
                #if os(iOS)
                Color(UIColor.systemGray5)
                #elseif os(macOS)
                Color(NSColor.systemGray)
                #endif
            case .thinking:
                Color.purple.opacity(0.1)
            case .unknown:
                Color.gray.opacity(0.2)
            }
        }
    }
    
    var textColor: Color {
        switch self {
        case .user: return .white
        default: return .primary
        }
    }
}

// MARK: - 工具扩展
extension String {
    func stripHTMLTags() -> String {
        replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
    }
}

// MARK: - JSON解析结构
struct RawConversation: Decodable {
    let messages: [RawMessage]
}

struct RawMessage: Decodable {
    let id: String
    let role: String
    let content: String
    let timestamp: Date?
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
