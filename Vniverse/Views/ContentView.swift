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
    @Query private var documents: [Document]
    @State private var selectedDocument: Document?
    @State private var showingFilePicker = false
    @State private var isEditing = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedDocument) {
                ForEach(documents) { document in
                    NavigationLink {
                        DocumentReaderView(document: document)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(document.title)
                                .font(.headline)
                            Text(document.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: isEditing ? deleteDocuments : nil)
            }
            .navigationTitle("文档")
            .toolbar {
                ToolbarItem {
                    Button(action: { showingFilePicker = true }) {
                        Label("打开文件", systemImage: "doc.badge.plus")
                    }
                }
                
                ToolbarItem {
                    Button(action: { isEditing.toggle() }) {
                        Label(isEditing ? "完成" : "编辑", 
                              systemImage: isEditing ? "checkmark.circle.fill" : "pencil")
                    }
                }
            }
        } detail: {
            if let document = selectedDocument {
                DocumentReaderView(document: document)
            } else {
                Text("选择一个文档开始阅读")
                    .foregroundStyle(.secondary)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.plainText, UTType(filenameExtension: "md")!],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                print("❌ 没有选择文件")
                return
            }
            
            // 开始访问文件
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ 无法访问文件：\(url.path)")
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let content = try String(contentsOf: url)
                print("✅ 成功读取文件内容，长度：\(content.count)")
                
                let document = Document(
                    title: url.lastPathComponent,
                    content: content,
                    path: url.path
                )
                
                // 使用主线程插入数据
                DispatchQueue.main.async {
                    withAnimation {
                        modelContext.insert(document)
                        print("✅ 成功插入文档：\(document.title)")
                        
                        // 自动选择新导入的文档
                        selectedDocument = document
                    }
                }
            } catch {
                print("❌ 文件导入错误: \(error.localizedDescription)")
            }
            
        case .failure(let error):
            print("❌ 文件选择错误: \(error.localizedDescription)")
        }
    }
    
    private func deleteDocuments(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(documents[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Document.self, inMemory: true)
}
