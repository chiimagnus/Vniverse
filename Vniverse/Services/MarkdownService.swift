//
// MarkdownService.swift
// Vniverse
//
// This file uses swift-markdown-ui (https://github.com/gonzalezreal/swift-markdown-ui)
// Copyright (c) 2020-2024 Guillermo Gonzalez
// Licensed under MIT License
//

import Foundation
import SwiftUI
import MarkdownUI

/// Markdown服务，使用 swift-markdown-ui 库解析和渲染Markdown文本
class MarkdownService {
    /// 单例实例
    static let shared = MarkdownService()
    
    /// 当前使用的 Markdown 主题
    private var currentTheme: Theme = .basic
    
    /// 图片资源的基础URL
    private var imageBaseURL: URL?
    
    private init() {
        // 初始化自定义主题
        setupCustomTheme()
    }
    
    /// 设置自定义 Markdown 主题
    private func setupCustomTheme() {
        // 创建一个自定义主题
        let vniverseTheme = Theme()
            // 文本样式
            .text {
                FontSize(.em(1.0))
                FontFamily(.system(.default))
                ForegroundColor(.primary)
            }
            // 强调文本样式
            .strong {
                FontWeight(.bold)
            }
            // 斜体样式
            .emphasis {
                FontStyle(.italic)
            }
            // 代码样式
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.85))
                BackgroundColor(Color(.sRGB, red: 0.95, green: 0.95, blue: 0.95, opacity: 1))
            }
            // 链接样式
            .link {
                ForegroundColor(.blue)
                UnderlineStyle(.single)
            }
            // 删除线样式
            .strikethrough {
                StrikethroughStyle(.single)
            }
            // 标题样式
            .heading1 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(2.0))
                        FontFamily(.system(.serif))
                        ForegroundColor(.primary)
                    }
                    .markdownMargin(top: 24, bottom: 16)
            }
            .heading2 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.75))
                        FontFamily(.system(.serif))
                        ForegroundColor(.primary)
                    }
                    .markdownMargin(top: 24, bottom: 16)
            }
            .heading3 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(.em(1.5))
                        FontFamily(.system(.serif))
                        ForegroundColor(.primary)
                    }
                    .markdownMargin(top: 24, bottom: 16)
            }
            .heading4 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(.em(1.25))
                        FontFamily(.system(.serif))
                        ForegroundColor(.primary)
                    }
                    .markdownMargin(top: 16, bottom: 16)
            }
            .heading5 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.medium)
                        FontSize(.em(1.125))
                        FontFamily(.system(.serif))
                        ForegroundColor(.primary)
                    }
                    .markdownMargin(top: 16, bottom: 16)
            }
            .heading6 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.medium)
                        FontSize(.em(1.0))
                        FontFamily(.system(.serif))
                        ForegroundColor(.primary)
                    }
                    .markdownMargin(top: 16, bottom: 16)
            }
            // 段落样式
            .paragraph { configuration in
                configuration.label
                    .relativeLineSpacing(.em(0.25))
                    .markdownMargin(top: 0, bottom: 12)
            }
            // 引用块样式
            .blockquote { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontStyle(.italic)
                        ForegroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.sRGB, red: 0.96, green: 0.96, blue: 0.96, opacity: 1))
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.secondary)
                            .frame(width: 4)
                    }
                    .markdownMargin(top: 0, bottom: 16)
            }
            // 代码块样式
            .codeBlock { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.85))
                    }
                    .padding()
                    .background(Color(.sRGB, red: 0.95, green: 0.95, blue: 0.95, opacity: 1))
                    .cornerRadius(8)
                    .markdownMargin(top: 0, bottom: 16)
            }
            // 列表样式
            .listItem { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.25))
            }
            // 图片样式
            .image { configuration in
                configuration.label
                    .cornerRadius(8)
                    .markdownMargin(top: 8, bottom: 8)
            }
            
        // 设置为当前主题
        self.currentTheme = vniverseTheme
    }
    
    /// 设置图片资源的基础URL
    /// - Parameter url: 基础URL
    func setImageBaseURL(_ url: URL?) {
        self.imageBaseURL = url
    }
    
    /// 切换 Markdown 主题
    /// - Parameter theme: 主题类型
    func setTheme(_ theme: MarkdownTheme) {
        switch theme {
        case .basic:
            self.currentTheme = .basic
        case .gitHub:
            self.currentTheme = .gitHub
        case .vniverse:
            setupCustomTheme()
        }
    }
    
    /// 创建 Markdown 视图
    /// - Parameter text: Markdown 文本
    /// - Returns: 渲染的视图
    func createMarkdownView(from text: String) -> some View {
        Markdown(text, baseURL: nil, imageBaseURL: imageBaseURL)
            .markdownTheme(currentTheme)
            .textSelection(.enabled)
    }
    
    /// 从文件 URL 加载并渲染 Markdown 视图
    /// - Parameter fileURL: Markdown 文件 URL
    /// - Returns: 渲染的视图或错误信息
    func createMarkdownViewFromFile(fileURL: URL) -> AnyView {
        do {
            let markdownContent = try String(contentsOf: fileURL, encoding: .utf8)
            return AnyView(
                createMarkdownView(from: markdownContent)
                    .navigationTitle(fileURL.deletingPathExtension().lastPathComponent)
            )
        } catch {
            return AnyView(
                Text("无法加载 Markdown 文件: \(error.localizedDescription)")
                    .foregroundColor(.red)
            )
        }
    }
    
    /// 使用预解析的 MarkdownContent 创建视图
    /// - Parameter content: 预解析的 MarkdownContent
    /// - Returns: 渲染的视图
    func createMarkdownView(from content: MarkdownContent) -> some View {
        Markdown(content, baseURL: nil, imageBaseURL: imageBaseURL)
            .markdownTheme(currentTheme)
            .textSelection(.enabled)
    }
    
    /// 预解析 Markdown 内容
    /// - Parameter text: Markdown 文本
    /// - Returns: 预解析的 MarkdownContent
    func parseMarkdownContent(_ text: String) -> MarkdownContent {
        MarkdownContent(text)
    }
}

/// Markdown 主题类型
enum MarkdownTheme {
    case basic
    case gitHub
    case vniverse
}

/// Markdown 文件查看器组件
struct MarkdownFileViewer: View {
    let fileURL: URL
    
    var body: some View {
        MarkdownService.shared.createMarkdownViewFromFile(fileURL: fileURL)
            .padding(.vertical)
    }
}
