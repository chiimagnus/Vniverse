import Foundation
import SwiftUI
import Markdown // 使用 Apple 的 swift-markdown 库 (Apache 2.0)

/// Markdown服务，使用官方Swift-Markdown库解析和渲染Markdown文本
class MarkdownService {
    /// 单例实例
    static let shared = MarkdownService()
    
    private init() {}
    
    /// 解析Markdown文本为Document对象
    /// - Parameter text: Markdown文本
    /// - Returns: 解析后的Document对象
    func parse(_ text: String) -> Markdown.Document {
        return Markdown.Document(parsing: text)
    }
    
    /// 将Markdown文本转换为AttributedString
    /// - Parameter text: Markdown文本
    /// - Returns: 格式化的AttributedString
    func parseToAttributedString(_ text: String) -> AttributedString {
        do {
            // 使用SwiftUI的原生Markdown解析能力
            return try AttributedString(markdown: text)
        } catch {
            print("🔴 Markdown解析错误: \(error)")
            return AttributedString(text)
        }
    }
    
    /// 创建Markdown视图
    /// - Parameter text: Markdown文本
    /// - Returns: 渲染的视图
    func createMarkdownView(from text: String) -> some View {
        let attributedText = parseToAttributedString(text)
        return SwiftUI.Text(attributedText)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    /// 从文件URL加载并渲染Markdown视图
    /// - Parameter fileURL: Markdown文件URL
    /// - Returns: 渲染的视图或错误信息
    func createMarkdownViewFromFile(fileURL: URL) -> some View {
        do {
            let markdownContent = try String(contentsOf: fileURL, encoding: .utf8)
            return createMarkdownView(from: markdownContent)
        } catch {
            return SwiftUI.Text("无法加载Markdown文件: \(error.localizedDescription)")
                .foregroundColor(.red)
        }
    }
}

/// Markdown文件查看器组件
struct MarkdownFileViewer: View {
    let fileURL: URL
    
    var body: some View {
        MarkdownService.shared.createMarkdownViewFromFile(fileURL: fileURL)
            .padding()
    }
} 
