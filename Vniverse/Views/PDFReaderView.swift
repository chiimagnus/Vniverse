import SwiftUI
import PDFKit

struct PDFReaderView: View {
    let document: Document
    @State private var pdfView = PDFView()
    
    var body: some View {
        PDFKitView(pdfView: pdfView)
            .navigationTitle(document.title)
            .onAppear {
                if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: document.sandboxPath)) {
                    pdfView.document = pdfDocument
                    pdfView.autoScales = true
                    pdfView.displayMode = .singlePage
                    pdfView.displayDirection = .vertical
                }
            }
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
