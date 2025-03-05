import SwiftUI
import Combine
import SwiftData
import AppKit

// Markdown视图模型，负责处理Markdown内容的加载和渲染
class MarkdownViewModel: ObservableObject {
    @Published var renderedContent: AnyView = AnyView(EmptyView())
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 缓存已渲染的内容，避免重复渲染
    private var contentCache: [Int: AnyView] = [:]
    
    func loadContent(document: Document) {
        // 检查缓存
        let contentHash = document.content.hashValue
        if let cachedView = contentCache[contentHash] {
            self.renderedContent = cachedView
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // 在后台线程处理Markdown渲染
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 分段处理大型Markdown文档
            let content = document.content
            
            DispatchQueue.main.async {
                // 渲染Markdown内容
                let markdownView = MarkdownService.shared.createMarkdownView(from: content)
                let wrappedView = AnyView(
                    markdownView
                        .padding(4)
                )
                
                // 缓存渲染结果
                self.contentCache[contentHash] = wrappedView
                self.renderedContent = wrappedView
                self.isLoading = false
            }
        }
    }
    
    func cleanup() {
        // 如果缓存过大，清理缓存
        if contentCache.count > 5 {
            contentCache.removeAll()
        }
    }
}

struct MarkdownReaderView: View {
    @ObservedObject var document: Document
    @StateObject private var audioController = AudioController()
    @StateObject private var viewModel = MarkdownViewModel()
    @State private var showSettings = false
    @Environment(\.modelContext) private var modelContext
    @State private var scrollPosition = ScrollPosition()
    @AppStorage("savePositionOnScroll") private var savePositionOnScroll: Bool = false
    
    // 防抖动保存函数
    @State private var saveTask: Task<Void, Never>?
    private func saveScrollPositionWithDebounce(proxy: ScrollViewProxy) {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3秒延迟
                if !Task.isCancelled, let yPosition = scrollPosition.y {
                    let positionString = String(format: "%.1f", yPosition)
                    document.saveReadingPosition(positionString)
                    try? modelContext.save()
                }
            } catch {}
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // 添加顶部安全区域，防止内容被导航栏遮挡
                    Spacer()
                        .frame(height: 16)
                        .id("top")
                    
                    if viewModel.isLoading {
                        loadingView
                    } else {
                        viewModel.renderedContent
                    }
                    
                    // 添加底部安全区域
                    Spacer()
                        .frame(height: 16)
                        .id("bottom")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: ScrollPosition(
                                y: geo.frame(in: .named("scroll")).origin.y * -1
                            )
                        )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { position in
                scrollPosition = position
                if savePositionOnScroll {
                    saveScrollPositionWithDebounce(proxy: proxy)
                }
            }
            .onAppear {
                // 使用带有延迟的内容加载，提高响应性
                Task {
                    viewModel.loadContent(document: document)
                    
                    if let lastPosition = document.lastReadPosition,
                       let offset = Double(lastPosition) {
                        // 延迟设置初始滚动位置，等待渲染完成
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                        withAnimation {
                            // 使用自定义视图ID来滚动到特定位置
                            proxy.scrollTo("top", anchor: .top)
                            // 模拟滚动到指定位置
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if let scrollView = NSApp.keyWindow?.firstResponder as? NSScrollView {
                                    scrollView.contentView.scroll(to: NSPoint(x: 0, y: offset))
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(document.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                audioControlToolbar
            }
        }
        .onDisappear {
            audioController.stop()
            // 在退出时保存阅读位置，而不是实时保存
            if let yPosition = scrollPosition.y {
                let positionString = String(format: "%.1f", yPosition)
                document.saveReadingPosition(positionString)
                document.unloadContent()
                viewModel.cleanup()
                try? modelContext.save()
            }
        }
    }
    
    // 加载中视图
    private var loadingView: some View {
        VStack {
            ProgressView()
                .controlSize(.large)
            Text("渲染Markdown内容...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var audioControlToolbar: some View {
        Group {
            if audioController.isSynthesizing {
                ProgressView()
                    .controlSize(.small)
            } else if audioController.isPlaying {
                Button(action: { audioController.pause() }) {
                    Image(systemName: "pause.fill")
                }
            } else {
                Button(action: { startPlayback() }) {
                    Image(systemName: "play.fill")
                }
            }
            
            Button(action: { audioController.stop() }) {
                Image(systemName: "stop.fill")
            }
            .disabled(!audioController.isPlaying && !audioController.isSynthesizing)
        }
    }
    
    private func startPlayback() {
        audioController.playDocument(content: document.content)
    }
}

// 用于在ScrollView中跟踪滚动位置的结构体
struct ScrollPosition: Equatable {
    var y: CGFloat? = nil
}

// 滚动位置偏好键
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue = ScrollPosition()
    
    static func reduce(value: inout ScrollPosition, nextValue: () -> ScrollPosition) {
        value = nextValue()
    }
} 