import SwiftUI
import Combine

struct MarkdownReaderView: View {
    @ObservedObject var document: Document
    @StateObject private var audioController = AudioController()
    @State private var showSettings = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if document.paragraphs.isEmpty {
                        Text(document.content)
                            .textSelection(.enabled)
                            .padding(4)
                    } else {
                        ForEach(document.paragraphs) { paragraph in
                            Text(paragraph.text)
                                .id(paragraph.id)
                                .padding(4)
                                .background(audioController.currentParagraph == paragraph.id ? Color.yellow.opacity(0.3) : Color.clear)
                                .onTapGesture { audioController.jumpTo(paragraph: paragraph) }
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: audioController.currentParagraph) { _, newValue in
                withAnimation {
                    if let newValue = newValue {
                        proxy.scrollTo(newValue, anchor: .center)
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
        .onDisappear { audioController.stop() }
    }
    
    private var audioControlToolbar: some View {
        HStack {
            if audioController.isSynthesizing {
                synthesisProgressView
            } else {
                playPauseButton
            }
            stopButton
        }
    }
    
    private var synthesisProgressView: some View {
        ProgressView()
            .controlSize(.small)
    }
    
    private var playPauseButton: some View {
        Group {
            if audioController.isPlaying {
                Button(action: { audioController.pause() }) {
                    Image(systemName: "pause.fill")
                }
            } else {
                Button(action: { startPlayback() }) {
                    Image(systemName: "play.fill")
                }
            }
        }
    }
    
    private var stopButton: some View {
        Button(action: { audioController.stop() }) {
            Image(systemName: "stop.fill")
        }
        .disabled(!audioController.isPlaying && !audioController.isSynthesizing)
    }
    
    private func startPlayback() {
        audioController.playDocument(content: document.content)
    }
} 