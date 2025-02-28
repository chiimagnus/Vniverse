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