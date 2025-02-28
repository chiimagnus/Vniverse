import SwiftUI
import Foundation

class HTMLParser {
    static func parse(_ htmlString: String) -> NSAttributedString {
        let data = Data(htmlString.utf8)
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            let attributedString = try NSAttributedString(
                data: data,
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
    
    var body: some View {
        Text(AttributedString(attributedString))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
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