# VoiceUniverse

<div align="center">
    <a href="README.md">中文</a> | <a>English</a>
</div>

VoiceUniverse is a macOS application designed for reading and managing PDF, Markdown, and AI-powered chat files, with natural voice narration support.

## 1. Features

- 🤖 AI Voice Synthesis Support, powered by the [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS) engine
- 📚 Support for reading Markdown documents
- 📚 Support for reading PDF documents
- 📚 Support for JSON chat logs (currently only compatible with JSON files exported by the [ChatHistoryBoxChromePlugin](https://github.com/chiimagnus/ChatHistoryBoxChromePlugin))

## 2. Project Structure

```
VoiceUniverse
├── Utils/
│   ├── AudioController.swift      # Document audio controller
│   ├── AudioPlaybackManager.swift # Audio playback manager
│   ├── ContentView+DocumentLink.swift  # Extension for ContentView to manage document links
│   └── HTMLParser.swift           # HTML parser
├── Services/
│   ├── GPTSovits.swift            # AI Voice Synthesis Engine
│   └── MarkdownService.swift      # Markdown parsing service
├── Views/                         # User Interface components
│   ├── ContentView.swift          # Main layout and navigation view
│   ├── JsonView/                  # Views related to JSON chat logs
│   │   ├── ErrorView.swift        # Error display view
│   │   ├── JsonReaderView.swift   # Main view for reading JSON files
│   │   └── MessageBubbleView.swift# Chat bubble component
│   ├── MarkdownView/              # Views for Markdown documents
│   │   └── MarkdownReaderView.swift # Main view for reading Markdown files
│   ├── PDFView/                   # Views for PDF documents
│   │   └── PDFReaderView.swift    # Main view for reading PDF files
│   └── SettingView/               # Settings views
│       ├── GPTSovitsSettingView.swift  # Settings for GPT-SoVITS voice synthesis
│       ├── BasicSettingView.swift       # Basic settings view
│       └── SettingsView.swift           # Global application settings
├── Models/
│   ├── JsonModels.swift           # JSON data models
│   └── Document.swift             # Document data model
└── VoiceUniverseApp.swift         # Application entry point
```

## 3. Acknowledgements

- [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui): Used for rendering Markdown content
- [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS): Used for voice synthesis

## 4. Support

If you find VoiceUniverse useful, please consider supporting our development:

<div align="center">
  <img src="https://github.com/chiimagnus/logseq-AIsearch/blob/master/public/buymeacoffee.jpg" width="400">
</div>
