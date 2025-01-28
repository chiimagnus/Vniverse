import SwiftUI

struct DocumentReaderView: View {
    let document: Document
    @State private var attributedContent: AttributedString = AttributedString()
    
    var body: some View {
        ScrollView {
            Text(attributedContent)
                .padding()
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(8)
        }
        .navigationTitle(document.title)
        .toolbar {
            ToolbarItem {
                Button(action: {
                    // TODO: 实现朗读功能
                }) {
                    Label("朗读", systemImage: "play.circle")
                }
            }
        }
        .onAppear {
            loadContent()
        }
        .onChange(of: document.content) { _, _ in
            loadContent()
        }
    }
    
    private func loadContent() {
        attributedContent = MarkdownService.shared.parseMarkdown(document.content)
    }
} 