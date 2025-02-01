import Combine
import Foundation

@MainActor
class AudioController: ObservableObject {
    // 播放状态
    @Published var isPlaying = false
    @Published var isSynthesizing = false
    @Published var currentProgress: Double = 0.0
    @Published var currentParagraph: String?
    @Published var errorMessage: String?
    
    private let playbackManager = AudioPlaybackManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 绑定播放器状态
        playbackManager.$isPlaying
            .assign(to: &$isPlaying)
        
        playbackManager.$isSynthesizing
            .assign(to: &$isSynthesizing)
        
        playbackManager.$currentProgress
            .assign(to: &$currentProgress)
        
        playbackManager.$errorMessage
            .assign(to: &$errorMessage)
    }
    
    // 统一播放控制方法
    func playDocument(content: String) {
        guard let refPath = UserDefaults.standard.string(forKey: "LastReferenceAudioPath") else {
            errorMessage = "请先在设置中配置参考音频"
            return
        }
        
        let promptText = UserDefaults.standard.string(forKey: "LastReferenceText") ?? ""
        playbackManager.startPlayback(
            text: content,
            referencePath: refPath,
            promptText: promptText
        )
    }
    
    func pause() { playbackManager.pausePlayback() }
    func resume() { playbackManager.resumePlayback() }
    func stop() { playbackManager.stopPlayback() }
    
    // 跳转到指定段落
    func jumpTo(paragraph: DocumentParagraph) {
        currentParagraph = paragraph.id
        // 这里可以添加实际的跳转逻辑，比如通知播放器跳转时间点
    }
} 
