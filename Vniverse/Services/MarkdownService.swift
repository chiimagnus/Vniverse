import Foundation
import SwiftUI

class MarkdownService {
    static let shared = MarkdownService()
    
    private init() {}
    
    func parseMarkdown(_ text: String) -> AttributedString {
        do {
            // 创建基本的解析选项
            let options = AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
            
            // 解析 Markdown
            var attributedString = try AttributedString(markdown: text, options: options)
            
            // 应用基本样式
            var container = AttributeContainer()
            container.foregroundColor = .primary
            container.font = .system(.body)
            attributedString.mergeAttributes(container)
            
            // 遍历并应用特定样式
            for run in attributedString.runs {
                var container = AttributeContainer()
                
                // 处理链接
                if run.link != nil {
                    container.foregroundColor = .blue
                    container.underlineStyle = .single
                    attributedString[run.range].mergeAttributes(container)
                }
                
                // 处理强调（粗体）
                if let inlineIntent = run.inlinePresentationIntent {
                    if inlineIntent == .stronglyEmphasized {
                        container.font = .system(.body, weight: .bold)
                        attributedString[run.range].mergeAttributes(container)
                    }
                    // 处理斜体
                    else if inlineIntent == .emphasized {
                        container.font = .system(.body, design: .serif, weight: .regular)
                        attributedString[run.range].mergeAttributes(container)
                    }
                }
                
                // 处理删除线
                if let _ = run.strikethroughStyle {
                    container.strikethroughStyle = .single
                    attributedString[run.range].mergeAttributes(container)
                }
            }
            
            return attributedString
            
        } catch {
            print("🔴 Markdown解析错误: \(error)")
            return AttributedString(text)
        }
    }
} 
