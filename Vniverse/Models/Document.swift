import Foundation
import SwiftData

@Model
final class Document: Identifiable {
    var id: UUID
    var title: String
    var content: String
    var fileName: String  // 只需要存储文件名
    var timestamp: Date
    
    init(title: String, content: String, fileName: String) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.fileName = fileName
        self.timestamp = Date()
        
        print("📄 创建文档：\(title)")
    }
    
    // 添加计算属性获取完整路径
    var sandboxPath: String {
        let appSupport = try! FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        return appSupport
            .appendingPathComponent("Documents")
            .appendingPathComponent(fileName)
            .path
    }
}

// 添加ModelContext扩展
extension ModelContext {
    func saveContext() {
        do {
            try save()
        } catch {
            print("❌ 保存失败: \(error)")
        }
    }
} 