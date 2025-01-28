import SwiftUI

struct DocumentReaderView: View {
    let document: Document
    @State private var attributedContent: AttributedString = AttributedString()
    @State private var scrollPosition: CGPoint = .zero
    
    var body: some View {
        ScrollView {
            Text(attributedContent)
                .padding()
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(8) // 增加行间距
                .background(GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).origin
                    )
                })
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            document.lastPosition = Int(-offset.y)
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
            print("📖 加载文档：\(document.title)")
            loadContent()
        }
        .onChange(of: document.content) { _, _ in
            print("📖 文档内容已更新：\(document.title)")
            loadContent()
        }
    }
    
    private func loadContent() {
        attributedContent = MarkdownService.shared.parseMarkdown(document.content)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                scrollPosition.y = CGFloat(-document.lastPosition)
            }
        }
    }
}

// 用于跟踪滚动位置的 PreferenceKey
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
} 