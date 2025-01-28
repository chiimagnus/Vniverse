import Foundation
import SwiftData

@Model
final class Document: Identifiable {
    var id: UUID
    var title: String
    var content: String
    var path: String
    var timestamp: Date
    var lastPosition: Int // 记录上次阅读位置
    
    init(title: String, content: String, path: String) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.path = path
        self.timestamp = Date()
        self.lastPosition = 0
        
        print("📄 创建文档：\(title)")
    }
} 