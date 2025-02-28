import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct MessageBubbleView: View {
    let message: Message
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
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
    
    private func roleIcon(_ role: MessageRole) -> some View {
        Image(systemName: role.iconName)
            .foregroundColor(role.iconColor)
            .frame(width: 20, height: 20)
    }
}