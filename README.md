<h1 align="center">
    VoiceUniverse
</h1>

<div align="center">
    <a>中文</a> | <a href="README.en.md">English</a>
</div>

VoiceUniverse是一款macOS平台的markdown阅读器，能够自然语音文本朗读和自动高亮朗读文本。

## 1. 功能特点
- [ ] 🎯 朗读文本自动高亮
- [ ] 📍 智能定位当前朗读位置
- 🤖 AI语音合成支持，基于 [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS) 引擎
- 📚 支持markdown文档阅读
- 📚 支持PDF文档阅读

## 2. 项目结构
```
VoiceUniverse
├── Utils/
│   ├── AudioController.swift # 文档音频控制器
│   └── AudioPlaybackManager.swift    # 音频播放管理器
├── Services/
│   ├── GPTSovits.swift          # AI语音合成引擎
│   └── MarkdownService.swift     # Markdown解析服务
├── Views/
│   ├── ContentView.swift         # 主视图（文档列表）
│   ├── MarkdownReaderView.swift  # Markdown阅读视图
│   ├── PDFReaderView.swift       # PDF阅读视图
│   ├── JsonReaderView.swift     # Json阅读视图
│   ├── SettingsView.swift        # 设置视图
│   └── GPTSovitsSettingView.swift # GPT-SoVITS设置视图
├── Models/
│   └── Document.swift            # 文档数据模型
└── VoiceUniverseApp.swift        # 主应用入口
```

## 3. 功能实现进度

### 第一阶段（基础功能）✓ 
#### Markdown基础功能 ✓
- [x] 实现Markdown文档的解析和显示
- [x] 支持基本文本格式（粗体、斜体、删除线）
- [x] 支持链接样式
- [x] 保留文本排版和换行
- [x] 添加文件导入/打开功能
- [x] 实现文档列表管理
- [x] 支持文档删除

#### 界面搭建 ✓
- [x] 完善主界面布局（分栏设计）
- [x] 实现文档阅读视图
- [x] 添加基础控制按钮（打开文件）
- [x] 添加设置面板

### 第二阶段（AI语音集成）✓ 
#### GPT-SoVITS集成 ✓
- [x] 完善GPTSovits.swift中的语音合成功能
- [x] 实现与GPT-SoVITS服务器的通信
- [x] 添加语音合成参数配置
- [x] 集成到文档阅读视图

<details>
<summary>完成了第二阶段的"集成到文档阅读视图"</summary>
- 1、我们主要使用到 @GPTSovits.swift 的流式输出功能，
- 2、而参数设置要使用 @GPTSovitsSettingView.swift 中的参数设置。参数设置中应该是有了默认参数，这个默认参数不需要更改，其中最主要的参数是：开启流式输出、按照短句进行文本切分。
- 3、我们可以在主视图上增加音频合成、播放按钮。
- LATER 4、不过要注意，既然想调用流式输出功能，那么就一定意味着播放和合成是不可分开的——其实这一点我存疑，我倒是希望能够分开，这样对于同一个文档来说，就不需要多次合成了，我们只需要将合成的音频保存起来即可。我们或许可以做两套音频播放，一套就是流式输出的音频播放（这个已经实现了），第二套就是对保存的wav格式的音频进行直接播放。
</details>

#### 语音控制功能 ✓
- [x] 实现播放控制面板（播放、暂停、停止）
- [x] 添加语音合成设置界面
- [x] 实现语音合成参数调节

### 第三阶段（高级功能）⚡ 进行中
#### 阅读体验优化
<details>
<summary>[ ]实现文本朗读时的高亮功能</summary>
我现在挺想做个朗读文本的文本实时高亮显示功能，依据我之前跟AI大量讨论的经验，最好的实现方案就是修改后端API的返回值，让后端返回一个高亮的文本或者时间戳等信息，然后再在前端进行高亮显示。
</details>

- [ ] 添加朗读位置智能追踪
- [x] 阅读进度自动保存
- [ ] 朗读进度自动保存

## 4. 支持
如果您觉得VoiceUniverse对您有帮助，欢迎赞助支持我们的开发：

<div align="center">
  <img src="https://github.com/chiimagnus/logseq-AIsearch/blob/master/public/buymeacoffee.jpg" width="400">
</div>
