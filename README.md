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
Vniverse：GPT-Sovits/Vniverse：GPT-Sovits
├── Speech/
│   └── GPTSovits.swift          # AI语音合成
├── Views/
│   ├── SettingsView.swift         # 设置视图
│   └── GPTSovitsSettingView.swift # GPT-SoVITS设置视图
│   └── ContentView.swift          # 主视图容器
├── Vniverse_GPT_SovitsApp.swift # 主应用
├── Models/
│   └── Document.swift                 # 文档模型
```

## 路线图

### 第一阶段（基础功能）
#### Markdown基础功能
- 实现Markdown文档的解析和显示
- 添加文件导入/打开功能
- 实现文档列表管理

#### 界面搭建
- 完善主界面布局
- 实现文档阅读视图
- 添加基础控制按钮（打开文件、切换文档等）

### 第二阶段（AI语音集成）
#### GPT-SoVITS集成
- 完善GPTSovits.swift中的语音合成功能
- 实现与GPT-SoVITS服务器的通信
- 添加语音合成参数配置

#### 语音控制功能
- 实现播放控制面板（播放、暂停、停止）
- 添加语音合成设置界面
- 实现语音合成参数调节

### 第三阶段（高级功能）
#### 阅读体验优化
- 实现文本朗读时的高亮功能
- 添加朗读位置智能追踪
- 实现阅读进度保存

#### 设置功能完善
- 完善SettingsView.swift中的配置选项
- 添加朗读偏好设置
- 实现配置的保存和加载

## 3. 支持
如果您觉得VoiceUniverse对您有帮助，欢迎赞助支持我们的开发：

[buymeacoffee](https://github.com/chiimagnus/logseq-AIsearch/blob/master/public/buymeacoffee.jpg)
<div align="center">
  <img src="https://github.com/chiimagnus/logseq-AIsearch/blob/master/public/buymeacoffee.jpg" width="400">
</div>
