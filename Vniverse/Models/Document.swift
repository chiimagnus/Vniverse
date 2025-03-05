/*
Document.swift
- 职责：这是应用的核心数据模型，用于管理用户文档
- 特点：
    - 使用SwiftData进行持久化存储
    - 包含文档的基本信息（标题、内容、文件类型等）
    - 处理文档的存储、加载和管理
    - 与文件系统交互，管理文档的物理存储
    - 支持文档的收藏、阅读位置等元数据
- 使用场景：
    - 文档列表展示
    - 文档的创建、编辑、删除
    - 文档的收藏状态管理
    - 文档的阅读进度跟踪
*/
import Foundation
import SwiftData
import Combine
import UniformTypeIdentifiers

// 添加文档类型枚举
enum DocumentType: Int, Codable, CaseIterable {
    case text
    case pdf
    case json
    
    var fileExtensions: [String] {
        switch self {
        case .text:
            return ["txt", "md"]
        case .pdf:
            return ["pdf"]
        case .json:
            return ["json"]
        }
    }
    
    var contentTypes: [UTType] {
        switch self {
        case .text:
            return [.plainText, UTType(filenameExtension: "md")!]
        case .pdf:
            return [.pdf]
        case .json:
            return [.json]
        }
    }
}

@Model
final class Document: ObservableObject, Identifiable {
    var id: UUID
    var title: String
    
    // 内容属性改为仅存储摘要，不再存储完整内容
    var contentPreview: String = ""  // 内容摘要，最多存储前1KB的内容
    var contentSize: Int = 0  // 文件大小（字节）
    
    // 用于标记内容是否已加载到内存
    @Transient
    private var _contentLoaded = false
    
    // 内容改为临时属性，不存入数据库
    @Transient
    private var _content: String = ""
    var content: String {
        get {
            if !_contentLoaded {
                loadContentIfNeeded()
            }
            return _content
        }
        set {
            _content = newValue
            contentSize = newValue.utf8.count
            // 存储内容摘要，最多1KB
            let previewLength = min(1024, newValue.count)
            contentPreview = String(newValue.prefix(previewLength))
            _contentLoaded = true
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
    
    // 新增收藏属性
    var isFavorite: Bool = false
    
    // 新增阅读位置属性
    var lastReadPosition: String?  // 存储位置标识（Markdown用段落ID，PDF用页面索引+位置）
    var lastReadTimestamp: Date?   // 最后阅读时间
    
    init(id: UUID = UUID(), title: String, content: String = "", fileName: String, fileType: DocumentType? = nil) {
        self.id = id
        self.title = title
        self.fileName = fileName
        self.timestamp = Date()
        
        // 如果没有指定文件类型，根据文件扩展名判断
        if let specifiedType = fileType {
            self.fileType = specifiedType
        } else {
            let ext = (fileName as NSString).pathExtension.lowercased()
            self.fileType = {
                switch ext {
                case "pdf": return .pdf
                case "json": return .json
                default: return .text
                }
            }()
        }
        
        // 设置内容
        self.content = content
        self.lastReadTimestamp = Date()
        print("📄 创建文档：\(title)")
    }
    
    // 在从数据库加载后初始化
    func didAwakeFromFetch() {
        // 记录内容未加载
        _contentLoaded = false
        
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
    
    // 按需加载内容
    private func loadContentIfNeeded() {
        // PDF文件不需要从文件加载内容
        if fileType == .pdf {
            _content = ""
            _contentLoaded = true
            return
        }
        
        let filePath = sandboxPath
        do {
            // 仅当文件存在且内容尚未加载时才加载
            if FileManager.default.fileExists(atPath: filePath) && !_contentLoaded {
                if contentSize > 5 * 1024 * 1024 { // 大于5MB的文件
                    // 对于大文件，仅加载前50KB作为预览
                    let fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: filePath))
                    let previewData = try fileHandle.read(upToCount: 50 * 1024) ?? Data()
                    try fileHandle.close()
                    _content = String(data: previewData, encoding: .utf8) ?? ""
                    _content += "\n\n[文件过大，仅显示部分内容...]"
                } else {
                    // 对于小文件，完整加载
                    _content = try String(contentsOfFile: filePath, encoding: .utf8)
                }
                _contentLoaded = true
            } else if !_contentLoaded {
                // 如果文件不存在但需要加载，返回预览内容
                _content = contentPreview
                _contentLoaded = true
            }
        } catch {
            print("❌ 文件加载失败: \(error)")
            _content = "加载失败: \(error.localizedDescription)"
            _contentLoaded = true
        }
    }
    
    // 释放内容，减少内存占用
    func unloadContent() {
        if !_contentLoaded { return }
        
        // 保留内容预览
        _content = ""
        _contentLoaded = false
        paragraphs = []
    }
    
    // 初始化段落
    private func initializeParagraphs() {
        // 只有文本文档才需要初始化段落
        if fileType == .text {
            let rawParagraphs = _content.components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            // 使用稳定的索引作为 id
            paragraphs = rawParagraphs.enumerated().map { index, paragraph in
                DocumentParagraph(id: "\(index)", text: paragraph)
            }
        } else {
            paragraphs = []
        }
    }
    
    // 新增位置保存方法
    func saveReadingPosition(_ position: String) {
        self.lastReadPosition = position
        self.lastReadTimestamp = Date()
        objectWillChange.send()
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
    let id: String
    let text: String
} 
