import SwiftUI

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
class SpeechViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var isSynthesizing = false
    @Published var currentParagraph: String?
    private var audioDataCache = Data()
    
    private var synthesisTask: Task<Void, Never>?
    
    // 开始播放文档
    func startPlay(document: Document) {
        stop()
        synthesisTask = Task {
            do {
                await MainActor.run { isSynthesizing = true }
                
                let params = loadParams()
                let text = document.content
                
                let audioStream = try await GPTSovits.shared.synthesizeStream(
                    text: text,
                    referenceAudioPath: UserDefaults.standard.string(forKey: "LastReferenceAudioPath"),
                    promptText: UserDefaults.standard.string(forKey: "LastReferenceText") ?? "",
                    params: params
                )
                
                try await GPTSovits.shared.playStream(audioStream)
                await MainActor.run { isPlaying = true }
            } catch {
                print("播放失败: \(error.localizedDescription)")
            }
            await MainActor.run { 
                isSynthesizing = false
                isPlaying = false
            }
        }
    }
    
    // 暂停播放
    func pause() {
        Task {
            await GPTSovits.shared.pause()
            await MainActor.run { isPlaying = false }
        }
    }
    
    // 恢复播放
    func resume() {
        Task {
            await GPTSovits.shared.resume()
            await MainActor.run { isPlaying = true }
        }
    }
    
    // 停止播放
    func stop() {
        synthesisTask?.cancel()
        Task {
            await GPTSovits.shared.stop()
            await MainActor.run {
                isPlaying = false
                isSynthesizing = false
            }
        }
    }
    
    // 跳转到指定段落
    func jumpTo(paragraph: DocumentParagraph) {
        // 实现段落跳转逻辑
        currentParagraph = paragraph.id
    }
    
    // 加载保存的参数
    private func loadParams() -> GPTSovitsSynthesisParams {
        var params = GPTSovitsSynthesisParams()
        
        // 从UserDefaults加载参数（与设置视图相同的逻辑）
        if let methodRawValue = UserDefaults.standard.string(forKey: "TextSplitMethod"),
           let method = TextSplitMethod(rawValue: methodRawValue) {
            params.textSplitMethod = method
        }
        
        params.batchSize = UserDefaults.standard.integer(forKey: "BatchSize")
        params.batchThreshold = UserDefaults.standard.double(forKey: "BatchThreshold")
        params.splitBucket = UserDefaults.standard.bool(forKey: "SplitBucket")
        params.streamingMode = UserDefaults.standard.bool(forKey: "StreamingMode")
        params.topK = UserDefaults.standard.integer(forKey: "TopK")
        params.topP = UserDefaults.standard.double(forKey: "TopP")
        params.temperature = UserDefaults.standard.double(forKey: "Temperature")
        params.repetitionPenalty = UserDefaults.standard.double(forKey: "RepetitionPenalty")
        params.parallelInfer = UserDefaults.standard.bool(forKey: "ParallelInfer")
        params.speedFactor = UserDefaults.standard.double(forKey: "SpeedFactor")
        params.fragmentInterval = UserDefaults.standard.double(forKey: "FragmentInterval")
        
        return params
    }
} 