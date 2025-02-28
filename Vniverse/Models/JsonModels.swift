import SwiftUI

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
        case .thinking: return "思考过程"
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

struct JSONErrorWrapper: LocalizedError, Equatable {
    let underlyingError: Error
    
    var errorDescription: String? {
        (underlyingError as? LocalizedError)?.errorDescription ?? underlyingError.localizedDescription
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }
}