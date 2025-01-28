<h1 align="center">
    VoiceUniverse
</h1>

<div align="center">
    <a>中文</a> | <a href="README.en.md">English</a>
</div>

VoiceUniverse是一款macOS平台的markdown阅读器，能够自然语音文本朗读和自动高亮朗读文本。

## 1. 功能特点
- 🎯 朗读文本自动高亮
- 📍 智能定位当前朗读位置
- 🤖 AI语音合成支持，基于 [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS) 引擎
- 📚 支持markdown文档阅读

## 2. 项目结构
```
VoiceUniverse
├── Speech/
│   └── GPTSovits.swift          # AI语音合成引擎
├── Services/
│   └── MarkdownService.swift     # Markdown解析服务
├── Views/
│   ├── ContentView.swift         # 主视图（文档列表）
│   ├── DocumentReaderView.swift  # 文档阅读视图
│   ├── SettingsView.swift        # 设置视图
│   └── GPTSovitsSettingView.swift # GPT-SoVITS设置视图
├── Models/
│   └── Document.swift            # 文档数据模型
└── VoiceUniverseApp.swift        # 主应用入口
```

## 3. 功能实现进度

### 第一阶段（基础功能）✓ 已完成
#### Markdown基础功能 ✓
- [x] 实现Markdown文档的解析和显示
  - [x] 支持基本文本格式（粗体、斜体、删除线）
  - [x] 支持链接样式
  - [x] 保留文本排版和换行
- [x] 添加文件导入/打开功能
- [x] 实现文档列表管理
  - [x] 支持文档删除
  - ~~记住阅读位置~~

#### 界面搭建 ✓
- [x] 完善主界面布局（分栏设计）
- [x] 实现文档阅读视图
- [x] 添加基础控制按钮（打开文件）

### 第二阶段（AI语音集成）⚡ 进行中
#### GPT-SoVITS集成
- [x] 完善GPTSovits.swift中的语音合成功能
- [x] 实现与GPT-SoVITS服务器的通信
- [x] 添加语音合成参数配置
- [ ] 集成到文档阅读视图

#### 语音控制功能
- [ ] 实现播放控制面板（播放、暂停、停止）
- [ ] 添加语音合成设置界面
- [ ] 实现语音合成参数调节

### 第三阶段（高级功能）⏳ 计划中
#### 阅读体验优化
- [ ] 实现文本朗读时的高亮功能
- [ ] 添加朗读位置智能追踪
- [ ] 实现阅读进度保存

#### 设置功能完善
- [ ] 完善SettingsView.swift中的配置选项
- [ ] 添加朗读偏好设置
- [ ] 实现配置的保存和加载

## 4. 使用说明
1. 点击工具栏的"打开文件"按钮导入Markdown文档
2. 在左侧列表中选择要阅读的文档
3. 在右侧阅读区域查看文档内容
4. 使用编辑按钮可以删除不需要的文档

## 5. 支持
如果您觉得VoiceUniverse对您有帮助，欢迎赞助支持我们的开发：

<div align="center">
  <img src="https://github.com/chiimagnus/logseq-AIsearch/blob/master/public/buymeacoffee.jpg" width="400">
</div>
