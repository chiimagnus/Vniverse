import Foundation
import Combine

@MainActor
class AudioPlaybackManager: ObservableObject {
    // 单例实例
    static let shared = AudioPlaybackManager()
    
    // 播放状态
    @Published var isPlaying = false
    @Published var isSynthesizing = false
    @Published var currentProgress: Double = 0.0
    @Published var errorMessage: String?
    
    // 内部属性
    private var synthesisTask: Task<Void, Never>?
    private var audioDataCache = Data()
    
    private init() {} // 防止外部初始化
    
    // MARK: - 公共接口
    
    /// 开始播放文本内容
    /// - Parameters:
    ///   - text: 要合成的文本
    ///   - referencePath: 参考音频路径
    ///   - promptText: 提示文本
    func startPlayback(text: String, referencePath: String?, promptText: String = "") {
        guard let refPath = referencePath else {
            showAlert(title: "缺少配置", message: "请先设置参考音频")
            return
        }
        
        stopPlayback()
        
        synthesisTask = Task {
            do {
                await MainActor.run { isSynthesizing = true }
                
                let params = GPTSovitsSynthesisParams.loadFromUserDefaults()
                let audioStream = try await GPTSovits.shared.synthesizeStream(
                    text: text,
                    referenceAudioPath: refPath,
                    promptText: promptText,
                    params: params
                )
                
                await MainActor.run { isPlaying = true }
                try await GPTSovits.shared.playStream(audioStream)
            } catch {
                handleError(error)
            }
            await MainActor.run {
                isSynthesizing = false
                isPlaying = false
            }
        }
    }
    
    /// 暂停播放
    func pausePlayback() {
        Task {
            await GPTSovits.shared.pause()
            isPlaying = false
        }
    }
    
    /// 恢复播放
    func resumePlayback() {
        Task {
            await GPTSovits.shared.resume()
            isPlaying = true
        }
    }
    
    /// 停止播放
    func stopPlayback() {
        synthesisTask?.cancel()
        Task {
            await GPTSovits.shared.stop()
            isPlaying = false
            isSynthesizing = false
            currentProgress = 0.0
        }
    }
    
    // MARK: - 私有方法
    
    private func handleError(_ error: Error) {
        if let sovitsError = error as? GPTSovitsError {
            switch sovitsError {
            case .serverNotAvailable:
                showAlert(title: "服务不可用", message: "请检查本地服务是否启动")
            case .synthesisError(let msg):
                showAlert(title: "合成错误", message: msg)
            default:
                showAlert(title: "播放错误", message: error.localizedDescription)
            }
        } else {
            // showAlert(title: "发生错误", message: error.localizedDescription)
        }
    }
    
    private func showAlert(title: String, message: String) {
        errorMessage = message
        print("⚠️ [\(title)] \(message)")
    }
    
    // 添加公共错误访问方法
    func getLastError() -> String? {
        return errorMessage
    }
} 