import Foundation

class MarkdownService {
    static let shared = MarkdownService()
    
    private init() {}
    
    func parseMarkdown(_ text: String) -> AttributedString {
        do {
            return try AttributedString(markdown: text)
        } catch {
            print("Markdown解析错误: \(error)")
            return AttributedString(text)
        }
    }
} 