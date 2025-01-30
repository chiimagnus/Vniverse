import Foundation
import SwiftData
import Combine
import UniformTypeIdentifiers

// 添加文档类型枚举
enum DocumentType: Int, Codable, CaseIterable {
    case text
    case pdf
    
    var fileExtensions: [String] {
        switch self {
        case .text:
            return ["txt", "md"]
        case .pdf:
            return ["pdf"]
        }
    }
    
    var contentTypes: [UTType] {
        switch self {
        case .text:
            return [.plainText, UTType(filenameExtension: "md")!]
        case .pdf:
            return [.pdf]
        }
    }
}

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
    var fileType: DocumentType = DocumentType.text // 使用完整的类型名称
    
    init(id: UUID = UUID(), title: String, content: String = "", fileName: String, fileType: DocumentType? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.fileName = fileName
        self.timestamp = Date()
        // 如果没有指定文件类型，根据文件扩展名判断
        if let specifiedType = fileType {
            self.fileType = specifiedType
        } else {
            let ext = (fileName as NSString).pathExtension.lowercased()
            self.fileType = ext == "pdf" ? .pdf : .text
        }
        initializeParagraphs()
        print("📄 创建文档：\(title)")
    }
    
    // 在从数据库加载后初始化
    func didAwakeFromFetch() {
        initializeParagraphs()
        // 确保文件类型与扩展名匹配
        let ext = (fileName as NSString).pathExtension.lowercased()
        if ext == "pdf" && fileType != .pdf {
            fileType = .pdf
        } else if ext != "pdf" && fileType != .text {
            fileType = .text
        }
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
        // 只有文本文档才需要初始化段落
        if fileType == .text {
            paragraphs = content
                .components(separatedBy: "\n\n")
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .map { DocumentParagraph(text: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        } else {
            paragraphs = []
        }
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