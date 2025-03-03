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
                VStack(alignment: .leading) {
                    Text(document.title)
                        .font(.headline)
                    // Text(document.fileName)
                    //     .font(.caption)
                    //     .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 收藏按钮
                Button(action: {
                    // 直接内联实现收藏状态切换
                    document.isFavorite.toggle()
                }) {
                    Image(systemName: document.isFavorite ? "star.fill" : "star")
                        .foregroundColor(document.isFavorite ? .yellow : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .contextMenu {
                Button {
                    // 直接内联实现收藏状态切换
                    document.isFavorite.toggle()
                } label: {
                    Label(document.isFavorite ? "取消收藏" : "收藏", 
                          systemImage: document.isFavorite ? "star.slash" : "star")
                }
                
                Button(role: .destructive) {
                    deleteDocument(document)
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
    }
}