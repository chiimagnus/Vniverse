import SwiftUI
import PDFKit
import AVFoundation

struct PDFReaderView: View {
    let document: Document
    @State private var pdfView = PDFView()
    @StateObject private var playbackManager = AudioPlaybackManager.shared
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        VStack {
            PDFKitView(pdfView: pdfView)
                .navigationTitle(document.title)
            
            // 添加控制工具栏
            HStack {
                Button {
                    if playbackManager.isPlaying {
                        playbackManager.stopPlayback()
                    } else {
                        startPlayback()
                    }
                } label: {
                    Image(systemName: playbackManager.isPlaying ? "pause.circle" : "speaker.wave.2.circle")
                        .font(.system(size: 24))
                }
                
                ProgressView(value: playbackManager.currentProgress, total: 100)
                    .frame(width: 200)
                
                Button {
                    playbackManager.stopPlayback()
                } label: {
                    Image(systemName: "stop.circle")
                        .font(.system(size: 24))
                }
            }
            .padding()
        }
        .onAppear {
            loadPDFDocument()
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "未知错误")
        }
        .onChange(of: playbackManager.errorMessage) { _, _ in
            if let message = playbackManager.errorMessage {
                errorMessage = message
                showError = true
            }
        }
    }
    
    private func loadPDFDocument() {
        if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: document.sandboxPath)) {
            pdfView.document = pdfDocument
            pdfView.autoScales = true
            pdfView.displayMode = .singlePage
            pdfView.displayDirection = .vertical
        }
    }
    
    private func startPlayback() {
        guard let refPath = UserDefaults.standard.string(forKey: "LastReferenceAudioPath") else {
            errorMessage = "请先在设置中配置参考音频"
            showError = true
            return
        }
        
        let promptText = UserDefaults.standard.string(forKey: "LastReferenceText") ?? ""
        let fullText = extractPDFText()
        
        playbackManager.startPlayback(
            text: fullText,
            referencePath: refPath,
            promptText: promptText
        )
    }
    
    private func extractPDFText() -> String {
        let content = pdfView.document?.string ?? ""
        // 进行必要的文本清洗
        return content
            .replacingOccurrences(of: "-\n", with: "")
            .replacingOccurrences(of: "\n", with: " ")
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
