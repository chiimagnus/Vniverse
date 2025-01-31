import SwiftUI
import PDFKit
import AVFoundation

struct PDFReaderView: View {
    let document: Document
    @State private var pdfView = PDFView()
    @State private var isSpeaking = false
    @State private var currentSpeakingPage = 0
    @State private var speechTask: Task<Void, Error>?
    @State private var audioProgress: Double = 0.0
    
    var body: some View {
        VStack {
            PDFKitView(pdfView: pdfView)
                .navigationTitle(document.title)
            
            // 添加控制工具栏
            HStack {
                Button {
                    if isSpeaking {
                        pauseSpeaking()
                    } else {
                        startSpeaking()
                    }
                } label: {
                    Image(systemName: isSpeaking ? "pause.circle" : "speaker.wave.2.circle")
                        .font(.system(size: 24))
                }
                
                ProgressView(value: audioProgress, total: 100)
                    .frame(width: 200)
                
                Button {
                    stopSpeaking()
                } label: {
                    Image(systemName: "stop.circle")
                        .font(.system(size: 24))
                }
                .disabled(!isSpeaking)
            }
            .padding()
        }
        .onAppear {
            if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: document.sandboxPath)) {
                pdfView.document = pdfDocument
                pdfView.autoScales = true
                pdfView.displayMode = .singlePage
                pdfView.displayDirection = .vertical
            }
        }
    }
    
    private func startSpeaking() {
        // 在Task开始时添加检查
        if UserDefaults.standard.string(forKey: "LastReferenceAudioPath") == nil {
            showAlert(title: "配置缺失", message: "请先前往语音设置选择参考音频")
            return
        }
        
        speechTask = Task {
            do {
                // 从UserDefaults获取用户设置的参考音频路径和提示文本
                let referenceAudioPath = UserDefaults.standard.string(forKey: "LastReferenceAudioPath")
                let promptText = UserDefaults.standard.string(forKey: "LastReferenceText") ?? ""
                
                // 检查是否已设置参考音频
                guard let refPath = referenceAudioPath else {
                    await MainActor.run {
                        showAlert(title: "缺少配置", message: "请先在设置中配置参考音频")
                    }
                    return
                }
                
                let totalPages = pdfView.document?.pageCount ?? 0
                for pageIndex in currentSpeakingPage..<totalPages {
                    guard let page = pdfView.document?.page(at: pageIndex) else { continue }
                    
                    // 提取PDF文本
                    let pageText = extractText(from: page)
                    
                    // 创建合成参数实例
                    var params = GPTSovitsSynthesisParams()
                    params.textSplitMethod = .punctuation
                    params.speedFactor = 1.2
                    
                    // 调用语音合成（使用全局配置）
                    let audioData = try await GPTSovits.shared.synthesize(
                        text: pageText,
                        referenceAudioPath: refPath,  // 使用用户配置的参考音频路径
                        promptText: promptText,      // 使用用户配置的提示文本
                        params: params,
                        maxRetries: 3
                    )
                    
                    // 更新UI状态（主线程更新）
                    await MainActor.run {
                        currentSpeakingPage = pageIndex
                        audioProgress = Double(pageIndex) / Double(totalPages) * 100
                    }
                    
                    // 播放音频
                    try await GPTSovits.shared.play(audioData)
                }
                await MainActor.run {
                    isSpeaking = false
                    audioProgress = 0.0
                }
            } catch {
                handleSpeechError(error)
            }
        }
    }
    
    private func pauseSpeaking() {
        Task {
            await GPTSovits.shared.pause()
            await MainActor.run {
                isSpeaking = false
            }
        }
        speechTask?.cancel()
    }
    
    private func stopSpeaking() {
        Task {
            await GPTSovits.shared.stop()
            await MainActor.run {
                isSpeaking = false
                currentSpeakingPage = 0
                audioProgress = 0.0
            }
        }
        speechTask?.cancel()
    }
    
    private func extractText(from page: PDFPage) -> String {
        let content = page.string ?? ""
        // 进行必要的文本清洗
        return content
            .replacingOccurrences(of: "-\n", with: "")
            .replacingOccurrences(of: "\n", with: " ")
    }
    
    private func handleSpeechError(_ error: Error) {
        if let sovitsError = error as? GPTSovitsError {
            switch sovitsError {
            case .serverNotAvailable:
                showAlert(title: "服务不可用", message: "请检查本地服务是否启动")
            case .synthesisError(let msg):
                showAlert(title: "合成错误", message: msg)
            default:
                showAlert(title: "播放错误", message: error.localizedDescription)
            }
        }
        stopSpeaking()
    }
    
    private func showAlert(title: String, message: String) {
        // 实现Alert显示逻辑
    }
}

struct PDFKitView: NSViewRepresentable {
    let pdfView: PDFView
    
    func makeNSView(context: Context) -> PDFView {
        pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        // 更新视图（如果需要）
    }
}
