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
    @Query(sort: \Document.timestamp, order: .reverse) private var documents: [Document]
    @State private var showingFilePicker = false
    @State private var selectedFileType: DocumentType = .text
    @SceneStorage("selectedDocumentID") private var selectedDocumentID: String?
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(documents) { document in
                    NavigationLink(value: document.id.uuidString) {
                        VStack(alignment: .leading) {
                            Text(document.title)
                                .font(.headline)
                            Text(document.fileName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteDocument(document)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: String.self) { documentID in
                Group {
                    if let document = documents.first(where: { $0.id.uuidString == documentID }) {
                        switch document.fileType {
                        case .text:
                            DocumentReaderView(document: document)
                                .id(document.id)
                        case .pdf:
                            PDFReaderView(document: document)
                                .id(document.id)
                        }
                    } else {
                        ContentUnavailableView("文档已删除", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("文档")
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button("导入文本文档") {
                            selectedFileType = .text
                            showingFilePicker = true
                        }
                        Button("导入PDF文档") {
                            selectedFileType = .pdf
                            showingFilePicker = true
                        }
                    } label: {
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
            allowedContentTypes: selectedFileType.contentTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }
    
    private func deleteDocument(_ document: Document) {
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
            guard let url = urls.first else { return }
            
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
                
                let content: String
                if selectedFileType == .text {
                    content = try String(contentsOf: url)
                } else {
                    content = "" // PDF文件不需要读取内容
                }
                
                let document = Document(
                    title: url.lastPathComponent,
                    content: content,
                    fileName: sandboxURL.lastPathComponent,
                    fileType: selectedFileType
                )
                
                DispatchQueue.main.async {
                    withAnimation {
                        modelContext.insert(document)
                        print("✅ 成功插入文档：\(document.title)")
                    }
                }
            } catch {
                print("❌ 文件导入错误: \(error.localizedDescription)")
            }
            
        case .failure(let error):
            print("❌ 文件选择错误: \(error.localizedDescription)")
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

#Preview {
    ContentView()
        .modelContainer(for: Document.self, inMemory: true)
}
