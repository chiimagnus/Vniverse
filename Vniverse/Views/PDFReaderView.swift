import SwiftUI
import PDFKit

struct PDFReaderView: View {
    let document: Document
    @StateObject private var audioController = AudioController()
    @State private var pdfView = PDFView()
    @State private var showError = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            PDFKitView(pdfView: pdfView)
                .navigationTitle(document.title)
        }
        .onAppear {
            loadPDFDocument()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                audioControlButtons
            }
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "未知错误")
        }
        .onReceive(audioController.$errorMessage) { message in
            errorMessage = message
            showError = message != nil
        }
    }
    
    // 音频控制按钮组
    private var audioControlButtons: some View {
        Group {
            if audioController.isSynthesizing {
                ProgressView()
                    .controlSize(.small)
            } else if audioController.isPlaying {
                Button(action: audioController.pause) {
                    Image(systemName: "pause.fill")
                }
            } else {
                Button(action: startPlayback) {
                    Image(systemName: "play.fill")
                }
            }
            
            Button(action: audioController.stop) {
                Image(systemName: "stop.fill")
            }
            .disabled(!audioController.isPlaying && !audioController.isSynthesizing)
        }
    }
    
    private func loadPDFDocument() {
        guard let pdfDocument = PDFDocument(url: URL(fileURLWithPath: document.sandboxPath)) else {
            errorMessage = "无法加载PDF文档"
            showError = true
            return
        }
        
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
    }
    
    private func startPlayback() {
        let content = extractPDFText()
        audioController.playDocument(content: content)
    }
    
    private func extractPDFText() -> String {
        guard let document = pdfView.document else { return "" }
        return document.string?
            .replacingOccurrences(of: "-\n", with: "")
            .replacingOccurrences(of: "\n", with: " ") ?? ""
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
