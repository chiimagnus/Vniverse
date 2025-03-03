//
//  ContentView+DocumentLink.swift
//  Vniverse
//
//  Created for document link extension
//

import SwiftUI

extension ContentView {
    /// 创建文档链接视图
    /// - Parameter document: 文档对象
    /// - Returns: 导航链接视图
    func documentLink(for document: Document) -> some View {
        NavigationLink(value: document.id.uuidString) {
            VStack(alignment: .leading) {
                Text(document.title)
                    .font(.headline)
                // Text(document.fileName)
                //     .font(.caption)
                //     .foregroundColor(.secondary)
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