import SwiftUI
import PDFKit

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct PDFReaderView: View {
    let document: Document
    @StateObject private var audioController = AudioController()
    @StateObject private var pdfViewModel = PDFViewModel()
    @State private var showError = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if pdfViewModel.isLoading {
                loadingView
            } else if pdfViewModel.pdfView.document != nil {
                PDFKitView(pdfView: pdfViewModel.pdfView)
                    .navigationTitle(document.title)
                    .overlay(
                        thumbnailOverlay
                            .opacity(pdfViewModel.showThumbnails ? 1 : 0)
                            .animation(.easeInOut(duration: 0.3), value: pdfViewModel.showThumbnails)
                    )
            } else {
                errorView
            }
        }
        .onAppear {
            pdfViewModel.loadPDFDocument(document: document)
        }
        .onDisappear {
            // 离开视图时释放内容以减少内存占用
            document.unloadContent()
            pdfViewModel.cleanup()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { pdfViewModel.showThumbnails.toggle() }) {
                    Image(systemName: "rectangle.grid.1x2")
                }
                
                Divider()
                
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
        .onReceive(pdfViewModel.$errorMessage) { message in
            errorMessage = message
            showError = message != nil
        }
    }
    
    // 加载中视图
    private var loadingView: some View {
        VStack {
            ProgressView()
                .controlSize(.large)
            Text("加载PDF文档中...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
    
    // 错误视图
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            Text("无法加载PDF文档")
                .font(.headline)
            Text(errorMessage ?? "未知错误")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("重试") {
                pdfViewModel.loadPDFDocument(document: document)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 缩略图覆盖视图
    private var thumbnailOverlay: some View {
        HStack {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 8) {
                    ForEach(0..<(pdfViewModel.pdfView.document?.pageCount ?? 0), id: \.self) { index in
                        if let page = pdfViewModel.pdfView.document?.page(at: index) {
                            Button(action: {
                                pdfViewModel.goToPage(index)
                                pdfViewModel.showThumbnails = false
                            }) {
                                PDFThumbnailView(page: page, isCurrentPage: pdfViewModel.currentPageIndex == index)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .frame(width: 120)
            .background(
                Color.black.opacity(0.8)
                    .cornerRadius(8, corners: .topRight)
            )
            
            Spacer()
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
    
    private func startPlayback() {
        // 只播放当前页面的内容
        if let currentPage = pdfViewModel.pdfView.currentPage {
            let content = currentPage.string ?? ""
            audioController.playDocument(content: content)
        }
    }
}

// PDF视图模型，负责处理PDF加载和状态管理
class PDFViewModel: ObservableObject {
    @Published var pdfView = PDFView()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showThumbnails = false
    @Published var currentPageIndex = 0
    
    private var pageChangeObserver: NSObjectProtocol?
    
    func loadPDFDocument(document: Document) {
        isLoading = true
        errorMessage = nil
        
        // 在后台线程加载PDF
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let url = URL(fileURLWithPath: document.sandboxPath)
            
            // 检查文件是否存在
            guard FileManager.default.fileExists(atPath: url.path) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "文件不存在: \(url.lastPathComponent)"
                }
                return
            }
            
            // 尝试加载PDF文档
            guard let pdfDocument = PDFDocument(url: url) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "无法解析PDF文档"
                }
                return
            }
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                self.pdfView.document = pdfDocument
                self.pdfView.autoScales = true
                self.pdfView.displayMode = .singlePageContinuous
                self.pdfView.displayDirection = .vertical
                
                // 恢复阅读位置
                if let position = document.lastReadPosition {
                    self.restorePDFPosition(position)
                }
                
                self.setupScrollObserver(document: document)
                self.isLoading = false
            }
        }
    }
    
    func cleanup() {
        // 移除观察者
        if let observer = pageChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            pageChangeObserver = nil
        }
        
        // 释放PDF文档
        pdfView.document = nil
    }
    
    func goToPage(_ index: Int) {
        guard let page = pdfView.document?.page(at: index) else { return }
        pdfView.go(to: page)
    }
    
    private func setupScrollObserver(document: Document) {
        // 移除旧的观察者
        if let observer = pageChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // 添加新的观察者
        pageChangeObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.saveCurrentPosition(document: document)
            
            // 更新当前页码
            if let currentPage = self.pdfView.currentPage,
               let index = self.pdfView.document?.index(for: currentPage) {
                self.currentPageIndex = index
            }
        }
    }
    
    private func saveCurrentPosition(document: Document) {
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
              let yPosition = Double(components[1]),
              let page = pdfView.document?.page(at: pageIndex) else { return }
        
        currentPageIndex = pageIndex
        
        let rect = CGRect(x: 0, 
                         y: CGFloat(yPosition),
                         width: page.bounds(for: .cropBox).width, 
                         height: 0)
        pdfView.go(to: rect, on: page)
    }
}

// PDF缩略图视图
struct PDFThumbnailView: View {
    let page: PDFPage
    let isCurrentPage: Bool
    
    var body: some View {
        ZStack {
            // 缩略图或替代背景
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 140)
                    .cornerRadius(4)
                
                if let thumbnail = page.thumbnail(of: CGSize(width: 100, height: 140), for: .cropBox) as NSImage? {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 140)
                        .cornerRadius(4)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isCurrentPage ? Color.blue : Color.clear, lineWidth: 2)
            )
            
            // 页码标签
            if let index = page.document?.index(for: page) {
                Text("\(index + 1)")
                    .font(.caption2)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .position(x: 20, y: 20)
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

// 扩展View以支持特定角落的圆角
extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// 自定义RectCorner枚举，兼容iOS和macOS
enum RectCorner: Int {
    case topLeft = 0
    case topRight = 1
    case bottomRight = 2
    case bottomLeft = 3
    case allCorners = 4
    
    #if os(iOS)
    var uiRectCorner: UIRectCorner {
        switch self {
        case .topLeft:
            return .topLeft
        case .topRight:
            return .topRight
        case .bottomRight:
            return .bottomRight
        case .bottomLeft:
            return .bottomLeft
        case .allCorners:
            return .allCorners
        }
    }
    #endif
}

// 自定义形状以支持特定角落的圆角
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        
        let topLeftRadius = corners == .topLeft || corners == .allCorners ? radius : 0
        let topRightRadius = corners == .topRight || corners == .allCorners ? radius : 0
        let bottomLeftRadius = corners == .bottomLeft || corners == .allCorners ? radius : 0
        let bottomRightRadius = corners == .bottomRight || corners == .allCorners ? radius : 0
        
        // 顶部左侧圆角
        path.move(to: CGPoint(x: topLeft.x + topLeftRadius, y: topLeft.y))
        
        // 顶部边
        path.addLine(to: CGPoint(x: topRight.x - topRightRadius, y: topRight.y))
        
        // 顶部右侧圆角
        if topRightRadius > 0 {
            path.addArc(
                center: CGPoint(x: topRight.x - topRightRadius, y: topRight.y + topRightRadius),
                radius: topRightRadius,
                startAngle: Angle(degrees: -90),
                endAngle: Angle(degrees: 0),
                clockwise: false
            )
        }
        
        // 右侧边
        path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y - bottomRightRadius))
        
        // 底部右侧圆角
        if bottomRightRadius > 0 {
            path.addArc(
                center: CGPoint(x: bottomRight.x - bottomRightRadius, y: bottomRight.y - bottomRightRadius),
                radius: bottomRightRadius,
                startAngle: Angle(degrees: 0),
                endAngle: Angle(degrees: 90),
                clockwise: false
            )
        }
        
        // 底部边
        path.addLine(to: CGPoint(x: bottomLeft.x + bottomLeftRadius, y: bottomLeft.y))
        
        // 底部左侧圆角
        if bottomLeftRadius > 0 {
            path.addArc(
                center: CGPoint(x: bottomLeft.x + bottomLeftRadius, y: bottomLeft.y - bottomLeftRadius),
                radius: bottomLeftRadius,
                startAngle: Angle(degrees: 90),
                endAngle: Angle(degrees: 180),
                clockwise: false
            )
        }
        
        // 左侧边
        path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y + topLeftRadius))
        
        // 顶部左侧圆角
        if topLeftRadius > 0 {
            path.addArc(
                center: CGPoint(x: topLeft.x + topLeftRadius, y: topLeft.y + topLeftRadius),
                radius: topLeftRadius,
                startAngle: Angle(degrees: 180),
                endAngle: Angle(degrees: 270),
                clockwise: false
            )
        }
        
        path.closeSubpath()
        return path
    }
}
