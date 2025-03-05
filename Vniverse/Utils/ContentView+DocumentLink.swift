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
                    document.isFavorite.toggle()
                    // 不在扩展中直接保存，而是使用防抖动函数
                    saveDocumentsWithDebounce()
                }) {
                    Label(
                        document.isFavorite ? "取消收藏" : "收藏",
                        systemImage: document.isFavorite ? "star.slash" : "star"
                    )
                }
                
                Button(role: .destructive, action: {
                    deleteDocument(document)
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