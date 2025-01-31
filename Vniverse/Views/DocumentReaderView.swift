import SwiftUI
import Combine

struct DocumentReaderView: View {
    @ObservedObject var document: Document
    @StateObject private var speechVM = SpeechViewModel()
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
                                .background(speechVM.currentParagraph == paragraph.id ? Color.yellow.opacity(0.3) : Color.clear)
                                .onTapGesture { speechVM.jumpTo(paragraph: paragraph) }
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: speechVM.currentParagraph) { _, newValue in
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
                if speechVM.isSynthesizing {
                    ProgressView()
                        .controlSize(.small)
                } else if speechVM.isPlaying {
                    Button(action: { speechVM.pause() }) {
                        Image(systemName: "pause.fill")
                    }
                } else {
                    Button(action: { speechVM.startPlay(document: document) }) {
                        Image(systemName: "play.fill")
                    }
                }
                
                Button(action: { speechVM.stop() }) {
                    Image(systemName: "stop.fill")
                }
                .disabled(!speechVM.isPlaying && !speechVM.isSynthesizing)
            }
        }
        .onDisappear { speechVM.stop() }
    }
}

// 新增语音控制视图模型
@MainActor
class SpeechViewModel: ObservableObject {
    @Published var currentParagraph: String?
    private let playbackManager = AudioPlaybackManager.shared
    
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isSynthesizing: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        playbackManager.$isPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)
        
        playbackManager.$isSynthesizing
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSynthesizing, on: self)
            .store(in: &cancellables)
    }
    
    func startPlay(document: Document) {
        let refPath = UserDefaults.standard.string(forKey: "LastReferenceAudioPath")
        let promptText = UserDefaults.standard.string(forKey: "LastReferenceText") ?? ""
        
        playbackManager.startPlayback(
            text: document.content,
            referencePath: refPath,
            promptText: promptText
        )
    }
    
    func pause() { playbackManager.pausePlayback() }
    func resume() { playbackManager.resumePlayback() }
    func stop() { playbackManager.stopPlayback() }
    
    // 跳转到指定段落
    func jumpTo(paragraph: DocumentParagraph) {
        // 实现段落跳转逻辑
        currentParagraph = paragraph.id
    }
} 