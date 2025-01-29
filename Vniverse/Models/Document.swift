import Foundation
import SwiftData
import Combine

@Model
final class Document: ObservableObject, Identifiable {
    var id: UUID
    var title: String
    var content: String {
        didSet {
            initializeParagraphs()
            objectWillChange.send()
        }
    }
    
    // SwiftData暂不支持存储复杂类型数组，改为临时计算属性
    @Transient
    private(set) var paragraphs: [DocumentParagraph] = []
    
    var fileName: String  // 只需要存储文件名
    var timestamp: Date
    
    init(id: UUID = UUID(), title: String, content: String, fileName: String) {
        self.id = id
        self.title = title
        self.content = content
        self.fileName = fileName
        self.timestamp = Date()
        initializeParagraphs()
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
    
    // 初始化段落
    private func initializeParagraphs() {
        paragraphs = content
            .components(separatedBy: "\n\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { DocumentParagraph(text: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }
    
    // 在从数据库加载后初始化段落
    func didAwakeFromFetch() {
        initializeParagraphs()
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

// 添加DocumentParagraph结构体
struct DocumentParagraph: Identifiable {
    let id = UUID().uuidString
    let text: String
} 