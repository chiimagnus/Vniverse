/*
2. JsonModels.swift
- 职责：处理与JSON数据相关的模型和解析逻辑
- 特点：
    - 主要用于JSON数据的解析和转换
    - 包含与JSON结构对应的数据模型
    - 处理JSON编码/解码错误
    - 定义与JSON数据相关的UI展示逻辑（如消息气泡样式）
- 使用场景：
    - 处理JSON格式的对话数据
    - 定义消息的角色（用户、助手等）及其展示样式
    - 处理JSON解析错误
    - 管理对话消息的UI展示逻辑
*/

import SwiftUI

// MARK: - 数据模型
struct Conversation: Identifiable {
    let id: String
    var messages: [Message]
    var isFavorite: Bool = false  // 添加对话级别的收藏属性
}

struct Message: Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    // let timestamp: Date?
}

enum MessageRole: String {
    case user
    case assistant
    case thinking
    case unknown
    
    var displayName: String {
        switch self {
        case .user: return "我"
        case .assistant: return UserDefaults.standard.string(forKey: "AIThinkingText") ?? "AI思考回复"
        case .thinking: return UserDefaults.standard.string(forKey: "AIThinkingText") ?? "AI思考回复"
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
        case .user: return Color(red: 0.0, green: 0.478, blue: 1.0)
        case .assistant: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .thinking: return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .unknown: return .gray
        }
    }
    
    var bubbleBackground: some View {
        Group {
            switch self {
            case .user:
                LinearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.478, blue: 1.0),
                        Color(red: 0.0, green: 0.478, blue: 1.0).opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .assistant:
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.15),
                        Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .thinking:
                Color(red: 0.6, green: 0.4, blue: 0.8).opacity(0.1)
            case .unknown:
                Color.gray.opacity(0.1)
            }
        }
    }
    
    var textColor: Color {
        switch self {
        case .user: return .white
        case .assistant: return .primary
        case .thinking: return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .unknown: return .gray
        }
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
    // let timestamp: Date?
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

struct JSONErrorWrapper: LocalizedError, Equatable {
    let underlyingError: Error
    
    var errorDescription: String? {
        (underlyingError as? LocalizedError)?.errorDescription ?? underlyingError.localizedDescription
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }
}