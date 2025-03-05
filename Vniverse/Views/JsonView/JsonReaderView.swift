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
    @State private var showFavoritesOnly = false  // 添加显示收藏过滤开关
    
    // 分页加载相关状态
    @State private var isLoading = false
    @State private var currentPage = 1
    @State private var hasMoreData = true
    @State private var pageSize = 5  // 每页显示的对话数量
    
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
                    // 添加收藏过滤开关
                    Toggle(isOn: $showFavoritesOnly) {
                        Label("只显示收藏对话", systemImage: "star.fill")
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    conversationListView
                    
                    // 加载更多按钮
                    if !parsedMessages.isEmpty && hasMoreData {
                        Button(action: loadMoreConversations) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .controlSize(.small)
                                        .padding(.trailing, 4)
                                }
                                Text(isLoading ? "加载中..." : "加载更多")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .disabled(isLoading)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                rawJSONToggle
            }
            .padding()
        }
        .navigationTitle(document.title)
        .onAppear(perform: parseJSON)
        .animation(.easeInOut, value: parsingError)
        .animation(.easeInOut, value: showFavoritesOnly)
        .alert("解析错误", isPresented: $showErrorAlert) {
            Button("确定") { }
        } message: {
            Text(parsingError?.errorDescription ?? "未知错误")
        }
        .onDisappear {
            // 离开视图时释放内容以减少内存占用
            document.unloadContent()
        }
    }
    
    // MARK: - 子视图
    
    // 对话列表视图
    private var conversationListView: some View {
        LazyVStack(spacing: 20) {
            // 显示的对话（分页和筛选）
            let displayedConversations = filteredConversations()
            
            // 收藏消息为空时的提示
            if showFavoritesOnly && !parsedMessages.contains(where: { $0.isFavorite }) {
                VStack(spacing: 16) {
                    Image(systemName: "star.slash")
                        .font(.largeTitle)
                        .foregroundColor(.yellow.opacity(0.5))
                    Text("暂无收藏对话")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
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
            
            ForEach(displayedConversations) { conversation in
                ConversationView(conversation: conversation, toggleFavorite: toggleConversationFavorite)
            }
        }
    }
    
    // 过滤显示的对话
    private func filteredConversations() -> [Conversation] {
        if showFavoritesOnly {
            return parsedMessages.filter { $0.isFavorite }
        }
        return parsedMessages
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
        
        // 重置分页状态
        currentPage = 1
        hasMoreData = true
        parsedMessages = []
        
        // 开始解析第一页
        loadMoreConversations()
    }
    
    // 加载更多对话
    private func loadMoreConversations() {
        guard !isLoading && hasMoreData else { return }
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 从文件加载JSON数据
                let content = document.content
                guard let data = content.data(using: .utf8) else {
                    throw JSONError.invalidEncoding
                }
                
                // 首次加载时准备预览JSON
                if currentPage == 1 {
                    let jsonObject = try JSONSerialization.jsonObject(with: data)
                    let formattedData = try JSONSerialization.data(
                        withJSONObject: jsonObject,
                        options: [.prettyPrinted, .sortedKeys]
                    )
                    let previewText = String(decoding: formattedData, as: UTF8.self)
                    
                    // 截取前10KB作为预览
                    let maxPreviewLength = 10 * 1024
                    let resultText = previewText.count > maxPreviewLength ?
                        previewText.prefix(maxPreviewLength) + "\n\n[文件过大，JSON预览已截断...]" :
                        previewText
                    
                    DispatchQueue.main.async {
                        formattedJSON = String(resultText)
                    }
                }
                
                // 解析对话（延迟加载）
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let rawData = try decoder.decode(RawConversation.self, from: data)
                
                // 按对话ID分组
                var allConversations: [String: Conversation] = [:]
                
                for message in rawData.messages {
                    let components = message.id.components(separatedBy: "-")
                    guard components.count >= 2 else { continue }
                    let conversationID = components.last!
                    
                    let role = MessageRole(rawValue: message.role) ?? .unknown
                    let newMessage = Message(
                        id: message.id,
                        role: role,
                        content: message.content
                    )
                    
                    if var existing = allConversations[conversationID] {
                        existing.messages.append(newMessage)
                        allConversations[conversationID] = existing
                    } else {
                        // 创建新对话，并从UserDefaults加载收藏状态
                        let isFavorite = UserDefaults.standard.bool(forKey: "conversation_favorite_\(conversationID)")
                        allConversations[conversationID] = Conversation(
                            id: conversationID,
                            messages: [newMessage],
                            isFavorite: isFavorite
                        )
                    }
                }
                
                // 获取所有对话并排序
                let sortedConversations = allConversations.values.sorted { $0.id < $1.id }
                
                // 分页处理
                let startIndex = (currentPage - 1) * pageSize
                let endIndex = min(startIndex + pageSize, sortedConversations.count)
                
                if startIndex < sortedConversations.count {
                    let newPage = Array(sortedConversations[startIndex..<endIndex])
                    
                    // 判断是否还有更多数据
                    let moreData = endIndex < sortedConversations.count
                    
                    DispatchQueue.main.async {
                        // 添加新页到现有结果
                        parsedMessages.append(contentsOf: newPage)
                        currentPage += 1
                        hasMoreData = moreData
                        isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        hasMoreData = false
                        isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    parsingError = JSONErrorWrapper(underlyingError: error)
                    isLoading = false
                }
            }
        }
    }
    
    // 切换对话收藏状态
    private func toggleConversationFavorite(_ conversation: Conversation) {
        // 在本地修改收藏状态
        if let conversationIndex = parsedMessages.firstIndex(where: { $0.id == conversation.id }) {
            // 切换收藏状态
            parsedMessages[conversationIndex].isFavorite.toggle()
            
            // 保存到UserDefaults
            UserDefaults.standard.set(
                parsedMessages[conversationIndex].isFavorite,
                forKey: "conversation_favorite_\(conversation.id)"
            )
        }
    }
}

// 提取会话视图组件，减少主视图复杂度
struct ConversationView: View {
    let conversation: Conversation
    let toggleFavorite: (Conversation) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 会话标题栏
            HStack {
                Text("对话 #\(conversation.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 折叠/展开按钮
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 4)
                
                // 收藏按钮
                Button(action: { toggleFavorite(conversation) }) {
                    Image(systemName: conversation.isFavorite ? "star.fill" : "star")
                        .foregroundColor(conversation.isFavorite ? .yellow : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 消息内容 - 只在展开时显示
            if isExpanded {
                LazyVStack(alignment: .leading, spacing: 8) {
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
                                    Text(UserDefaults.standard.string(forKey: "AIThinkingText") ?? "AI思考回复")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // 思考过程折叠部分
                                DisclosureGroup {
                                    message.content.parseHTML()
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
                                nextMessage!.content.parseHTML()
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
                            MessageBubbleView(
                                message: message, 
                                nextMessage: nextMessage
                            )
                        }
                    }
                }
            } else {
                // 折叠状态的预览
                HStack {
                    let previewText = conversation.messages.first?.content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) ?? ""
                    Text(String(previewText.prefix(50)) + (previewText.count > 50 ? "..." : ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 4)
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
