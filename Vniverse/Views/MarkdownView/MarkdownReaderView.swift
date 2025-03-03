import SwiftUI
import Combine
import SwiftData
import AppKit

// 自定义包装的 OffsetScrollView，用于跟踪和控制滚动位置
struct OffsetScrollView<Content: View>: NSViewRepresentable {
    @Binding var offset: CGFloat   // 当前滚动偏移量（单位：像素）
    let content: Content
    
    init(offset: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        self._offset = offset
        self.content = content()
    }
    
    class Coordinator: NSObject {
        var offset: Binding<CGFloat>
        var isSettingOffset = false
        
        init(offset: Binding<CGFloat>) {
            self.offset = offset
            super.init()
        }
        
        // 监听 NSClipView 的 bounds 变化（滚动时会触发）
        @objc func boundsDidChange(notification: Notification) {
            guard !isSettingOffset else { return }
            if let clipView = notification.object as? NSClipView {
                let newOffset = clipView.bounds.origin.y
                // print("滚动位置更新：\(newOffset)")
                offset.wrappedValue = newOffset
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(offset: $offset)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        
        // 初始化 NSHostingView 来展示 SwiftUI 内容
        let hostingView = NSHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = hostingView
        
        // 让 hostingView 的宽度匹配 ScrollView 的宽度
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            hostingView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor)
        ])
        
        // 允许 contentView 发送 bounds 变化的通知
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.boundsDidChange),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        // 更新显示内容
        if let hostingView = scrollView.documentView as? NSHostingView<Content> {
            hostingView.rootView = content
        }
        
        // 如果当前实际滚动位置与绑定的 offset 差异较大，则调整滚动
        let currentOffset = scrollView.contentView.bounds.origin.y
        if abs(currentOffset - offset) > 1.0 {
            context.coordinator.isSettingOffset = true
            scrollView.contentView.scroll(to: NSPoint(x: 0, y: offset))
            scrollView.reflectScrolledClipView(scrollView.contentView)
            context.coordinator.isSettingOffset = false
            print("程序设置滚动位置：\(offset)")
        }
    }
}

struct MarkdownReaderView: View {
    @ObservedObject var document: Document
    @StateObject private var audioController = AudioController()
    @State private var showSettings = false
    @Environment(\.modelContext) private var modelContext
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        OffsetScrollView(offset: $scrollOffset) {
            LazyVStack(alignment: .leading, spacing: 8) {
                MarkdownService.shared.createMarkdownView(from: document.content)
                    .padding(4)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onChange(of: scrollOffset) { _, newValue in
            let positionString = String(format: "%.1f", newValue)
            // print("保存滚动位置：\(positionString)")
            document.saveReadingPosition(positionString)
            try? modelContext.save()
        }
        .navigationTitle(document.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                audioControlToolbar
            }
        }
        .onAppear {
            print("视图出现，文档标题：\(document.title)")
            print("上次阅读位置：\(document.lastReadPosition ?? "无")")
            
            if let lastPosition = document.lastReadPosition,
               let offset = Double(lastPosition) {
                print("尝试恢复到位置：\(offset)")
                // 延迟设置初始滚动位置
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    scrollOffset = CGFloat(offset)
                }
            }
        }
        .onDisappear {
            audioController.stop()
            let positionString = String(format: "%.1f", scrollOffset)
            print("视图消失，保存最终位置：\(positionString)")
            document.saveReadingPosition(positionString)
            try? modelContext.save()
        }
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