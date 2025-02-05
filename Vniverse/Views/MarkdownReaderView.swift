import SwiftUI
import Combine
import SwiftData
import AppKit

struct MarkdownReaderView: View {
    @ObservedObject var document: Document
    @StateObject private var audioController = AudioController()
    @State private var showSettings = false
    @Environment(\.modelContext) private var modelContext
    @State private var currentVisibleParagraphID: String?
    
    var body: some View {
        GeometryReader { containerGeometry in
            let centerY = containerGeometry.size.height / 2
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if document.paragraphs.isEmpty {
                            Text(document.content)
                                .textSelection(.enabled)
                                .padding(4)
                                .id("single_content")  // 为单一内容添加ID
                                .background {
                                    GeometryReader { geometry in
                                        Color.clear.preference(
                                            key: ScrollOffsetPreferenceKey.self,
                                            value: [ScrollOffsetData(id: "single_content", rect: geometry.frame(in: .named("scroll")))]
                                        )
                                    }
                                }
                        } else {
                            ForEach(document.paragraphs) { paragraph in
                                Text(paragraph.text)
                                    .id(paragraph.id)
                                    .padding(4)
                                    .background(audioController.currentParagraph == paragraph.id ? Color.yellow.opacity(0.3) : Color.clear)
                                    .onTapGesture { audioController.jumpTo(paragraph: paragraph) }
                                    .textSelection(.enabled)
                                    .background {
                                        GeometryReader { geometry in
                                            Color.clear.preference(
                                                key: ScrollOffsetPreferenceKey.self,
                                                value: [ScrollOffsetData(id: paragraph.id, rect: geometry.frame(in: .named("scroll")))]
                                            )
                                        }
                                    }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { data in
                    // 使用外层 GeometryReader 计算得到的 centerY
                    if let closestParagraph = data.min(by: { abs($0.rect.midY - centerY) < abs($1.rect.midY - centerY) }) {
                        if currentVisibleParagraphID != closestParagraph.id {
                            currentVisibleParagraphID = closestParagraph.id
                            document.saveReadingPosition(closestParagraph.id)
                            modelContext.saveContext()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: audioController.currentParagraph) { _, newValue in
                    withAnimation {
                        if let newValue = newValue {
                            proxy.scrollTo(newValue, anchor: .center)
                            document.saveReadingPosition(newValue)
                            modelContext.saveContext()
                        }
                    }
                }
                .onAppear {
                    if let lastPosition = document.lastReadPosition {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                proxy.scrollTo(lastPosition, anchor: .center)
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
            if let currentID = currentVisibleParagraphID {
                document.saveReadingPosition(currentID)
                modelContext.saveContext()
            }
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

// 添加用于跟踪滚动位置的辅助类型
struct ScrollOffsetData: Equatable {
    let id: String
    let rect: CGRect
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: [ScrollOffsetData] = []
    
    static func reduce(value: inout [ScrollOffsetData], nextValue: () -> [ScrollOffsetData]) {
        value.append(contentsOf: nextValue())
    }
} 