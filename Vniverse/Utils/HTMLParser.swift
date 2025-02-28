import SwiftUI
import Foundation

class HTMLParser {
    static func parse(_ htmlString: String) -> NSAttributedString {
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            // 添加基本的CSS样式
            let styledHTML = """
            <style>
            body { font-family: -apple-system, system-ui; line-height: 1.5; }
            h1, h2, h3, h4, h5, h6 { margin: 1em 0 0.5em 0; }
            p { margin: 0.5em 0; }
            ul, ol { margin: 0.5em 0; padding-left: 2em; }
            li { margin: 0.25em 0; }
            code { font-family: Menlo, Monaco, monospace; background-color: rgba(0,0,0,0.05); padding: 0.2em 0.4em; border-radius: 3px; }
            pre { background-color: rgba(0,0,0,0.05); padding: 1em; border-radius: 5px; overflow-x: auto; }
            strong { font-weight: 600; }
            </style>
            (htmlString)
            """
            
            let attributedString = try NSAttributedString(
                data: Data(styledHTML.utf8),
                options: options,
                documentAttributes: nil
            )
            return attributedString
        } catch {
            return NSAttributedString(string: htmlString)
        }
    }
    
    static func parseToView(_ htmlString: String) -> some View {
        let parsedString = parse(htmlString)
        return HTMLContentView(attributedString: parsedString)
    }
}

struct HTMLContentView: View {
    let attributedString: NSAttributedString
    @State private var showCopyButton = false
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if attributedString.string.contains("md-code-block") {
                codeBlockView
            } else {
                Text(AttributedString(attributedString))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
        }
    }
    
    private var codeBlockView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(action: {
                    copyToClipboard(attributedString.string)
                    isCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isCopied = false
                    }
                }) {
                    Text(isCopied ? "已复制" : "复制")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                Text(AttributedString(attributedString))
                    .textSelection(.enabled)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
            }
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

// 扩展String以添加HTML解析功能
extension String {
    func parseHTML() -> some View {
        HTMLParser.parseToView(self)
    }
    
    // 移除所有HTML标签，保留纯文本
    func stripHTMLTags() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        
        do {
            let attributedString = try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
            return attributedString.string
        } catch {
            return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        }
    }
}