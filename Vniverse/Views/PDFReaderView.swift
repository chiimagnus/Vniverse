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
            setupScrollObserver()
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
        
        // 恢复阅读位置
        if let position = document.lastReadPosition {
            restorePDFPosition(position)
        }
    }
    
    private func setupScrollObserver() {
        NotificationCenter.default.addObserver(forName: .PDFViewPageChanged, 
                                              object: pdfView, 
                                               queue: .main) { _ in
            saveCurrentPosition()
        }
    }
    
    private func saveCurrentPosition() {
        guard let page = pdfView.currentPage,
              let pageIndex = pdfView.document?.index(for: page) else { return }
        
        let visibleRect = pdfView.convert(pdfView.bounds, to: page)
        let position = "\(pageIndex):\(visibleRect.minY)"
        document.saveReadingPosition(position)
    }
    
    private func restorePDFPosition(_ position: String) {
        let components = position.components(separatedBy: ":")
        guard components.count == 2,
              let pageIndex = Int(components[0]),
              let yPosition = CGFloat(components[1]),
              let page = pdfView.document?.page(at: pageIndex) else { return }
        
        let rect = CGRect(x: 0, y: yPosition, width: page.bounds(for: .cropBox).width, height: 0)
        pdfView.go(to: rect, on: page)
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
