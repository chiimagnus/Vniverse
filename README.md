<h1 align="center">
    VoiceUniverse
</h1>

<div align="center">
    <a>中文</a> | <a href="README.en.md">English</a>
</div>

Vniverse是一款macOS平台的pdf、markdown、AI 聊天保存软件，并且能够自然语音朗读文本。

## 1. 功能特点
- 🤖 AI语音合成支持，基于 [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS) 引擎
- 📚 支持markdown文档阅读
- 📚 支持PDF文档阅读
- 📚 支持json聊天记录，目前只支持 [ChatHistoryBoxChromePlugin](https://github.com/chiimagnus/ChatHistoryBoxChromePlugin) 插件导出的json文件


## 2. 项目结构
```
VoiceUniverse
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
└── VoiceUniverseApp.swift       # 主应用入口
```


## 3. 鸣谢
- [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui), 用于渲染Markdown内容
- [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS)，用于语音合成

## 4. 支持
如果您觉得VoiceUniverse对您有帮助，欢迎赞助支持我们的开发：

<div align="center">
  <img src="https://github.com/chiimagnus/logseq-AIsearch/blob/master/public/buymeacoffee.jpg" width="400">
</div>
