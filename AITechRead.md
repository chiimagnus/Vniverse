# 技术开发文档

## 1. 项目结构
```
Vniverse
├── Utils/
│   ├── AudioController.swift # 文档音频控制器
│   ├── AudioPlaybackManager.swift    # 音频播放管理器
│   ├── ContentView+DocumentLink.swift    # ContentView 的扩展文件，主要用于创建和管理文档链接视图的功能
│   └── HTMLParser.swift # HTML解析器
├── Services/
│   ├── GPTSovits.swift          # AI语音合成引擎
│   └── MarkdownService.swift     # Markdown解析服务
├── Views/                        # 视图层目录
│   ├── ContentView.swift         # 主内容视图，负责整体布局和导航
│   ├── JsonView/                 # JSON聊天记录相关视图
│   │   ├── ErrorView.swift       # 错误提示视图
│   │   ├── JsonReaderView.swift  # JSON文件阅读器主视图
│   │   └── MessageBubbleView.swift # 聊天气泡组件视图
│   ├── MarkdownView/            # Markdown文档相关视图
│   │   └── MarkdownReaderView.swift # Markdown阅读器主视图
│   ├── PDFView/                 # PDF文档相关视图
│   │   └── PDFReaderView.swift  # PDF阅读器主视图
│   └── SettingView/             # 设置相关视图
│       ├── GPTSovitsSettingView.swift # GPT-SoVITS语音合成设置视图
│       ├── BasicSettingView.swift # 基本设置视图
│       └── SettingsView.swift    # 应用全局设置视图
├── Models/
│   ├── JsonModels.swift         # Json数据模型
│   └── Document.swift           # 文档数据模型
└── VniverseApp.swift       # 主应用入口
```

## 2. 各个文件中的主要函数名列表

### Utils/
- **AudioController.swift**
  - `playDocument()`
  - `pause()`
  - `resume()`
  - `stop()`
  - `jumpTo()`

- **AudioPlaybackManager.swift**
  - `startPlayback()`
  - `pausePlayback()`
  - `resumePlayback()`
  - `stopPlayback()`
  - `handleError()`

- **ContentView+DocumentLink.swift**
  - `createDocumentLink()`
  - `manageDocumentLinks()`
  - `openDocument()`

- **HTMLParser.swift**
  - `parseHTML()`
  - `stripHTMLTags()`
  - `convertToPlainText()`

### Services/
- **GPTSovits.swift**
  - `synthesize()`
  - `synthesizeStream()`
  - `play()`
  - `pause()`
  - `stop()`
  - `checkServerStatus()`

- **MarkdownService.swift**
  - `parseMarkdown()`
  - `renderToHTML()`
  - `convertToAttributedString()`

### Views/
- **ContentView.swift**
  - `loadDocument()`
  - `showSettings()`
  - `toggleSidebar()`

- **ErrorView.swift**
  - `showError()`
  - `dismissError()`

- **JsonReaderView.swift**
  - `loadJsonFile()`
  - `parseConversation()`
  - `toggleExpansion()`

- **MessageBubbleView.swift**
  - `renderMessageContent()`
  - `applyMessageStyle()`

- **MarkdownReaderView.swift**
  - `loadMarkdownFile()`
  - `renderMarkdown()`
  - `startPlayback()`

- **PDFReaderView.swift**
  - `loadPDFDocument()`
  - `renderPDFPage()`

- **GPTSovitsSettingView.swift**
  - `saveParams()`
  - `loadDefaultSettings()`
  - `testSynthesis()`

- **BasicSettingView.swift**
  - `savePreferences()`
  - `resetToDefaults()`

- **SettingsView.swift**
  - `applySettings()`
  - `restoreDefaults()`

### Models/
- **JsonModels.swift**
  - `Message.init()`
  - `Conversation.init()`
  - `parseFromJSON()`

- **Document.swift**
  - `loadFromFile()`
  - `saveToFile()`
  - `getFileType()`

### VoiceUniverseApp.swift
- `setupAppEnvironment()`
- `handleOpenURL()`
- `initializeServices()`

