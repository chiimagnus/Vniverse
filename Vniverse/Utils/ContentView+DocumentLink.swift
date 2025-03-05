//
//  ContentView+DocumentLink.swift
//  Vniverse
//
//  Created for document link extension
//

import SwiftUI
import SwiftData

extension ContentView {
    /// 创建文档链接视图
    /// - Parameter document: 文档对象
    /// - Returns: 导航链接视图
    func documentLink(for document: Document) -> some View {
        NavigationLink(value: document.id.uuidString) {
            HStack {
                documentIcon(for: document.fileType)
                
                VStack(alignment: .leading) {
                    Text(document.title)
                        .lineLimit(1)
                    
                    if let lastReadTimestamp = document.lastReadTimestamp {
                        Text("上次阅读: \(lastReadTimestamp, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if document.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            .contextMenu {
                Button(action: {
                    // 如果有多选，则对所有选中的文档操作
                    if !selectedDocumentIDs.isEmpty {
                        let docsToUpdate = selectedDocumentIDs.contains(document.id.uuidString) 
                            ? documents.filter { selectedDocumentIDs.contains($0.id.uuidString) }
                            : [document]
                        toggleFavorite(for: docsToUpdate)
                    } else {
                        toggleFavorite(for: [document])
                    }
                }) {
                    // 如果是多选且包含当前文档，则根据所有选中的文档状态决定显示文本
                    Label(
                        {
                            if selectedDocumentIDs.contains(document.id.uuidString) && selectedDocumentIDs.count > 1 {
                                // 检查所有选中文档是否都已收藏
                                let selectedDocs = documents.filter { selectedDocumentIDs.contains($0.id.uuidString) }
                                let allFavorited = !selectedDocs.contains { !$0.isFavorite }
                                return allFavorited ? "全部取消收藏" : "全部收藏"
                            } else {
                                return document.isFavorite ? "取消收藏" : "收藏"
                            }
                        }(),
                        systemImage: {
                            if selectedDocumentIDs.contains(document.id.uuidString) && selectedDocumentIDs.count > 1 {
                                // 检查所有选中文档是否都已收藏
                                let selectedDocs = documents.filter { selectedDocumentIDs.contains($0.id.uuidString) }
                                let allFavorited = !selectedDocs.contains { !$0.isFavorite }
                                return allFavorited ? "star.slash" : "star"
                            } else {
                                return document.isFavorite ? "star.slash" : "star"
                            }
                        }()
                    )
                }
                .keyboardShortcut("s", modifiers: [])
                
                Divider()
                
                Button(role: .destructive, action: {
                    // 如果有多选，则对所有选中的文档操作
                    if !selectedDocumentIDs.isEmpty {
                        let docsToDelete = selectedDocumentIDs.contains(document.id.uuidString)
                            ? documents.filter { selectedDocumentIDs.contains($0.id.uuidString) }
                            : [document]
                        deleteDocuments(docsToDelete)
                    } else {
                        deleteDocuments([document])
                    }
                }) {
                    Label("删除", systemImage: "trash")
                }
            }
        }
        .tag(document.id.uuidString)
    }
    
    // 获取文档图标
    @ViewBuilder
    func documentIcon(for fileType: DocumentType) -> some View {
        switch fileType {
        case .text:
            Image(systemName: "doc.text")
                .foregroundColor(.blue)
        case .pdf:
            Image(systemName: "doc.viewfinder")
                .foregroundColor(.red)
        case .json:
            Image(systemName: "curlybraces")
                .foregroundColor(.orange)
        }
    }
    
    // 日期格式化
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}