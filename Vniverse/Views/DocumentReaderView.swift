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
                // 使用 ScrollViewReader 跟踪滚动位置
                .background(GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).origin
                    )
                })
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            // 保存阅读位置
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
            attributedContent = MarkdownService.shared.parseMarkdown(document.content)
            // 恢复上次阅读位置
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    scrollPosition.y = CGFloat(-document.lastPosition)
                }
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