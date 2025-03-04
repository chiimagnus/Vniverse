import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct MessageBubbleView: View {
    let message: Message
    let nextMessage: Message?
    @State private var isThinkingExpanded = false
    
    init(message: Message, nextMessage: Message? = nil) {
        self.message = message
        self.nextMessage = nextMessage
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        if message.role == .user || message.role == .assistant || 
           message.role == .thinking {
            standardMessageView
        } else {
            standardMessageView
        }
    }
    
    private var standardMessageView: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                HStack {
                    if message.role == .user {
                        Text(message.role.displayName)
                            .font(.caption)
                            .foregroundColor(message.role.textColor)
                        roleIcon(message.role)
                    } else {
                        roleIcon(message.role)
                        Text(message.role.displayName)
                            .font(.caption)
                            .foregroundColor(message.role.textColor)
                    }
                }
                
                if message.role == .thinking {
                    thinkingContentView
                } else {
                    contentView(for: message)
                }
                
                // if let time = message.timestamp {
                //     Text(timeFormatter.string(from: time))
                //         .font(.caption2)
                //         .foregroundColor(.secondary)
                // }
            }
            
            if message.role != .user {
                Spacer()
            }
        }
    }
    
    private var thinkingContentView: some View {
        DisclosureGroup(isExpanded: $isThinkingExpanded) {
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
    }
    
    private func contentView(for message: Message) -> some View {
        VStack {
            // 使用HTMLParser解析和渲染HTML内容
            message.content.parseHTML()
                .foregroundColor(message.role.textColor)
                .padding(.vertical, message.role == .user ? 12 : 8)
                .padding(.horizontal, message.role == .user ? 16 : 12)
                .frame(maxWidth: message.role == .user ? 300 : .infinity, alignment: .leading)
                .background(
                    message.role.bubbleBackground
                        .cornerRadius(8)
                )
                .font(message.role == .user ? .body : .subheadline)
                .shadow(color: message.role == .user ? .blue.opacity(0.2) : .clear, radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: message.role == .user ? 16 : 8)
                        .stroke(message.role == .user ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        }
    }
    
    private func roleIcon(_ role: MessageRole) -> some View {
        Image(systemName: role.iconName)
            .foregroundColor(role.iconColor)
            .frame(width: 20, height: 20)
    }
}