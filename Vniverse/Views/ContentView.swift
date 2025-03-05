//
//  ContentView.swift
//  Vniverse
//
//  Created by chii_magnus on 2025/1/28.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Document.timestamp, order: .reverse) var documents: [Document]
    @State private var showingFilePicker = false
    @SceneStorage("selectedDocumentID") private var selectedDocumentID: String?
    @State var selectedDocumentIDs: Set<String> = []
    
    // 支持的所有文件类型
    private var supportedTypes: [UTType] {
        DocumentType.allCases.flatMap { $0.contentTypes }
    }
    
    // 批量收藏/取消收藏选中的文档
    func toggleFavorite(for documents: [Document]) {
        withAnimation {
            // 检查是否所有文档都已收藏
            let allFavorited = !documents.contains { !$0.isFavorite }
            
            // 如果全部已收藏，则取消收藏；否则，将未收藏的都收藏
            for document in documents {
                if allFavorited {
                    // 全部已收藏，全部取消
                    document.isFavorite = false
                } else if !document.isFavorite {
                    // 有未收藏的，只将未收藏的设为收藏
                    document.isFavorite = true
                }
                // 已收藏的保持不变，除非所有都已收藏
            }
            saveDocumentsWithDebounce()
        }
    }
    
    // 批量删除文档
    func deleteDocuments(_ documents: [Document]) {
        withAnimation {
            for document in documents {
                deleteDocument(document)
                selectedDocumentIDs.remove(document.id.uuidString)
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedDocumentIDs) {
                // 收藏文档分类
                Section(header: Label("收藏文档", systemImage: "star.fill").foregroundColor(.yellow)) {
                    ForEach(documents.filter { $0.isFavorite }) { document in
                        documentLink(for: document)
                    }
                    
                    if !documents.contains(where: { $0.isFavorite }) {
                        Text("暂无收藏文档")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                // 按文件类型分组显示文档
                Section(header: Label("Markdown文档", systemImage: "doc.text")) {
                    DocumentListView(documents: documents.filter { $0.fileType == .text },
                                  selectedDocumentID: $selectedDocumentID,
                                  documentLink: documentLink)
                }
                
                Section(header: Label("PDF文档", systemImage: "doc.viewfinder")) {
                    DocumentListView(documents: documents.filter { $0.fileType == .pdf },
                                  selectedDocumentID: $selectedDocumentID,
                                  documentLink: documentLink)
                }
                
                Section(header: Label("JSON文档", systemImage: "curlybraces")) {
                    DocumentListView(documents: documents.filter { $0.fileType == .json },
                                  selectedDocumentID: $selectedDocumentID,
                                  documentLink: documentLink)
                }
            }
            .listStyle(.sidebar)
            .navigationDestination(for: String.self) { documentID in
                DocumentContentView(documentID: documentID, documents: documents)
            }
            .navigationTitle("文档")
            .navigationSplitViewColumnWidth(
                min: 200, 
                ideal: 250, 
                max: 300
            )
            .toolbar {
                ToolbarItem {
                    Button(action: { showingFilePicker = true }) {
                        Label("导入文档", systemImage: "doc.badge.plus")
                    }
                }
            }
        } detail: {
            if documents.isEmpty {
                ContentUnavailableView(
                    "没有文档",
                    systemImage: "doc.badge.plus",
                    description: Text("点击工具栏的\"导入文档\"按钮导入文档")
                )
            } else {
                ContentUnavailableView(
                    "选择文档",
                    systemImage: "doc.text",
                    description: Text("从左侧列表选择一个文档开始阅读")
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: supportedTypes,
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .onAppear {
            setupNotificationObserver()
        }
        .onDisappear {
            removeNotificationObserver()
        }
        // 优化：限制文档变化监听频率，提高性能
        .onChange(of: documents) { _, _ in
            // 使用防抖动延迟保存，避免频繁保存
            saveDocumentsWithDebounce()
        }
    }
    
    // 防抖动保存，避免频繁IO操作
    @State private var saveTask: Task<Void, Never>?
    func saveDocumentsWithDebounce() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒延迟
                if !Task.isCancelled {
                    try modelContext.save()
                }
            } catch {
                print("❌ 文档状态保存失败: \(error)")
            }
        }
    }
    
    // 设置通知观察者
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ImportDocument"),
            object: nil,
            queue: .main
        ) { _ in
            showingFilePicker = true
        }
    }
    
    // 移除通知观察者
    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name("ImportDocument"),
            object: nil
        )
    }
    
    func deleteDocument(_ document: Document) {
        withAnimation {
            if document.id.uuidString == selectedDocumentID {
                selectedDocumentID = nil
            }
            cleanupDocumentFiles(document)
            modelContext.delete(document)
        }
    }
    
    private func cleanupDocumentFiles(_ document: Document) {
        let appSupport = try! FileManager.default.url(
            for: .applicationSupportDirectory, 
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        
        let fileURL = appSupport
            .appendingPathComponent("Documents")
            .appendingPathComponent(document.fileName)
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("🗑️ 成功删除沙箱文件: \(document.fileName)")
            }
        } catch {
            print("❌ 沙箱文件删除失败: \(error.localizedDescription)")
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                importFile(from: url)
            }
        case .failure(let error):
            print("❌ 文件选择错误: \(error.localizedDescription)")
        }
    }
    
    private func importFile(from url: URL) {
        let fileName = url.lastPathComponent
        if documents.contains(where: { $0.fileName == fileName }) {
            print("⚠️ 文档已存在: \(fileName)")
            return
        }
        
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ 无法访问文件：\(url.path)")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let sandboxURL = try saveToSandbox(url: url)
            
            // 根据文件扩展名判断类型
            let ext = url.pathExtension.lowercased()
            let fileType: DocumentType = switch ext {
                case "pdf": .pdf
                case "json": .json
                default: .text
            }
            
            // 获取文件大小
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: sandboxURL.path)
            let fileSize = fileAttributes[.size] as? Int ?? 0
            
            var content = ""
            if fileType == .text || fileType == .json {
                // 对于超过5MB的文件，仅加载前10KB作为预览
                if fileSize > 5 * 1024 * 1024 {
                    let fileHandle = try FileHandle(forReadingFrom: sandboxURL)
                    let previewData = try fileHandle.read(upToCount: 10 * 1024) ?? Data()
                    try fileHandle.close()
                    content = String(data: previewData, encoding: .utf8) ?? ""
                } else {
                    // 对于较小的文件，完整加载
                    content = try String(contentsOf: sandboxURL)
                }
            }
            
            let document = Document(
                title: url.lastPathComponent,
                content: content,
                fileName: sandboxURL.lastPathComponent,
                fileType: fileType
            )
            
            DispatchQueue.main.async {
                withAnimation {
                    modelContext.insert(document)
                    print("✅ 成功插入文档：\(document.title)，大小：\(fileSize) 字节")
                }
            }
        } catch {
            print("❌ 文件导入错误: \(error.localizedDescription)")
        }
    }
    
    private func saveToSandbox(url: URL) throws -> URL {
        let fileManager = FileManager.default
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let documentsDirectory = appSupport.appendingPathComponent("Documents")
        let targetURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
        
        try fileManager.createDirectory(
            at: documentsDirectory,
            withIntermediateDirectories: true
        )
        
        if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }
        
        try fileManager.copyItem(at: url, to: targetURL)
        return targetURL
    }
}

// 优化文档列表性能的专用视图组件
struct DocumentListView: View {
    let documents: [Document]
    @Binding var selectedDocumentID: String?
    let documentLink: (Document) -> any View
    
    var body: some View {
        ForEach(documents) { document in
            AnyView(documentLink(document))
        }
    }
}

// 优化文档内容加载的专用视图组件
struct DocumentContentView: View {
    let documentID: String
    let documents: [Document]
    
    var body: some View {
        Group {
            if let document = documents.first(where: { $0.id.uuidString == documentID }) {
                switch document.fileType {
                case .text:
                    MarkdownReaderView(document: document)
                        .id(document.id)
                case .pdf:
                    PDFReaderView(document: document)
                        .id(document.id)
                case .json:
                    JsonReaderView(document: document)
                        .id(document.id)
                }
            } else {
                ContentUnavailableView("文档已删除", systemImage: "trash")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Document.self, inMemory: true)
}
