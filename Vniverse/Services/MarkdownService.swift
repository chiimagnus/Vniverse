import Foundation
import SwiftUI
import Markdown // 使用 Apple 的 swift-markdown 库 (Apache 2.0)

/// Markdown服务，使用官方Swift-Markdown库解析和渲染Markdown文本
class MarkdownService {
    /// 单例实例
    static let shared = MarkdownService()
    
    /// 基础样式配置
    private var bodyFont: Font = .system(.body)
    private var headingFont: Font = .system(.title3, design: .serif, weight: .semibold)
    private var codeFont: Font = .system(.body, design: .monospaced)
    private var linkColor: Color = .blue
    private var codeBackground: Color = Color(.sRGB, red: 0.95, green: 0.95, blue: 0.95, opacity: 1)
    private var quoteColor: Color = .secondary
    private var quoteBackground: Color = Color(.sRGB, red: 0.96, green: 0.96, blue: 0.96, opacity: 1)
    private var headingColor: Color = .primary
    
    // 段落间距
    private var paragraphSpacing: CGFloat = 12.0
    // 元数据区域样式
    private var metadataColor: Color = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.6, opacity: 1)
    
    private init() {}
    
    /// 设置文本字体
    /// - Parameter font: 字体
    func setBodyFont(_ font: Font) {
        self.bodyFont = font
    }
    
    /// 设置标题字体
    /// - Parameter font: 字体
    func setHeadingFont(_ font: Font) {
        self.headingFont = font
    }
    
    /// 设置链接颜色
    /// - Parameter color: 颜色
    func setLinkColor(_ color: Color) {
        self.linkColor = color
    }
    
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
            var attributedString = try AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
            
            // 应用基本样式
            attributedString = applyBasicStyles(to: attributedString)
            
            return attributedString
        } catch {
            print("🔴 Markdown解析错误: \(error)")
            return AttributedString(text)
        }
    }
    
    /// 应用基本样式
    private func applyBasicStyles(to attributedString: AttributedString) -> AttributedString {
        var result = attributedString
        
        // 遍历所有样式范围
        for run in result.runs {
            let range = run.range
            
            // 应用正文字体作为基础字体
            result[range].font = bodyFont
            
            // 处理各种Markdown元素
            if let intent = result[range].presentationIntent {
                let description = String(describing: intent)
                
                // 处理标题
                if description.contains("heading") {
                    // 提取标题级别
                    var level = 1
                    for i in 1...6 {
                        if description.contains("level: \(i)") {
                            level = i
                            break
                        }
                    }
                    
                    // 根据级别设置不同样式
                    switch level {
                    case 1:
                        result[range].font = .system(size: 32, weight: .bold, design: .serif)
                        result[range].foregroundColor = headingColor
                        
                    case 2:
                        result[range].font = .system(size: 28, weight: .bold, design: .serif)
                        result[range].foregroundColor = headingColor
                        
                    case 3:
                        result[range].font = .system(size: 24, weight: .semibold, design: .serif)
                        result[range].foregroundColor = headingColor
                        
                    case 4:
                        result[range].font = .system(size: 20, weight: .semibold, design: .serif)
                        result[range].foregroundColor = headingColor
                        
                    case 5:
                        result[range].font = .system(size: 18, weight: .medium, design: .serif)
                        result[range].foregroundColor = headingColor
                        
                    case 6:
                        result[range].font = .system(size: 16, weight: .medium, design: .serif)
                        result[range].foregroundColor = headingColor
                        
                    default:
                        result[range].font = .system(size: 16, weight: .medium, design: .serif)
                    }
                    
                    // 标题周围添加额外间距
//                    result[range].paragraphStyle = createParagraphStyle(spacing: paragraphSpacing * 1.5)
                }
                
                // 引用块样式
                if description.contains("blockQuote") {
                    result[range].foregroundColor = quoteColor
                    result[range].font = bodyFont.italic()
                    result[range].backgroundColor = quoteBackground
                    
//                    // 创建带有左侧边框的段落样式
//                    _ = DispatchQueue.main.sync {
//                        let style = NSMutableParagraphStyle()
//                        style.headIndent = 20
//                        style.firstLineHeadIndent = 20
//                        style.paragraphSpacing = paragraphSpacing
//                        style.paragraphSpacingBefore = paragraphSpacing
//                        return style
//                    }
//                    // 在主线程上设置paragraphStyle属性
//                    DispatchQueue.main.sync {
//                        result[range].paragraphStyle = paragraphStyle
//                    }
                }
                
                // 列表项样式
                if description.contains("listItem") {
                    // 提取列表级别
                    var level = 0
                    if description.contains("orderedList") || description.contains("unorderedList") {
                        for i in 0...5 {
                            if description.contains("nestingLevel: \(i)") {
                                level = i
                                break
                            }
                        }
                    }
                    
                    // 根据嵌套级别设置缩进
                    _ = DispatchQueue.main.sync {
                        let style = NSMutableParagraphStyle()
                        style.headIndent = 20 * CGFloat(level + 1)
                        style.firstLineHeadIndent = 20 * CGFloat(level + 1) - 10
                        style.paragraphSpacing = paragraphSpacing * 0.5
                        return style
                    }
//                    // 在主线程上设置paragraphStyle属性
//                    DispatchQueue.main.sync {
//                        result[range].paragraphStyle = paragraphStyle
//                    }
                }
                
                // 检测元数据区域 (处理YAML前端)
                if description.contains("ThematicBreak") {
                    result[range].foregroundColor = metadataColor
                    result[range].font = .system(.caption, design: .monospaced)
                    
//                    _ = DispatchQueue.main.sync {
//                        let style = NSMutableParagraphStyle()
//                        style.paragraphSpacing = paragraphSpacing
//                        return style
//                    }
//                    // 在主线程上设置paragraphStyle属性
//                    DispatchQueue.main.sync {
//                        result[range].paragraphStyle = paragraphStyle
//                    }
                }
            }
            
            // 处理链接
            if result[range].link != nil {
                result[range].foregroundColor = linkColor
                result[range].underlineStyle = .single
                result[range].font = bodyFont.bold()
            }
            
            // 处理行内代码
            if result[range].inlinePresentationIntent == .code {
                result[range].font = codeFont
                result[range].backgroundColor = codeBackground
                // 注意：新版API中不再支持直接设置padding
                // 可以考虑使用其他方式添加内边距，如自定义视图或容器
            }
            
            // 处理行内样式
            if let presentationIntent = result[range].inlinePresentationIntent {
                // 使用更安全的方式处理行内样式
                if presentationIntent == .emphasized {
                    result[range].font = bodyFont.italic()
                } else if presentationIntent == .stronglyEmphasized {
                    result[range].font = bodyFont.bold()
                } else if presentationIntent == .strikethrough {
                    result[range].strikethroughStyle = .single
                }
            }
        }
        
        return result
    }
    
    /// 创建段落样式
//    private func createParagraphStyle(spacing: CGFloat) -> NSParagraphStyle {
//        // 使用主线程创建段落样式，避免Sendable一致性问题
//        let style = DispatchQueue.main.sync {
//            let paragraphStyle = NSMutableParagraphStyle()
//            paragraphStyle.paragraphSpacingBefore = spacing
//            paragraphStyle.paragraphSpacing = spacing
//            paragraphStyle.lineSpacing = 4
//            return paragraphStyle
//        }
//        return style
//    }
    
    /// 创建Markdown视图
    /// - Parameter text: Markdown文本
    /// - Returns: 渲染的视图
    func createMarkdownView(from text: String) -> some View {
        let attributedText = parseToAttributedString(text)
        
        return VStack(alignment: .leading, spacing: 0) {
            SwiftUI.Text(attributedText)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 从文件URL加载并渲染Markdown视图
    /// - Parameter fileURL: Markdown文件URL
    /// - Returns: 渲染的视图或错误信息
    func createMarkdownViewFromFile(fileURL: URL) -> some View {
        do {
            let markdownContent = try String(contentsOf: fileURL, encoding: .utf8)
            return createMarkdownView(from: markdownContent)
                .navigationTitle(fileURL.deletingPathExtension().lastPathComponent)
        } catch {
            return SwiftUI.Text("无法加载Markdown文件: \(error.localizedDescription)")
                .foregroundColor(.red)
        }
    }
    
    /// 处理和显示Markdown中的图片
    func renderMarkdownImage(url: URL?) -> some View {
        Group {
            if let imageURL = url {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(8)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                            .frame(height: 200)
                    @unknown default:
                        EmptyView()
                    }
                }
                .padding(.vertical, 8)
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .frame(height: 100)
            }
        }
    }
}

/// Markdown文件查看器组件
struct MarkdownFileViewer: View {
    let fileURL: URL
    
    var body: some View {
        MarkdownService.shared.createMarkdownViewFromFile(fileURL: fileURL)
            .padding(.vertical)
    }
}
