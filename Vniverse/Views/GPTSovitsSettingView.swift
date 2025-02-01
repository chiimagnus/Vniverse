import SwiftUI

struct GPTSovitsSettingView: View {
    // 测试用的默认文本
    private let defaultText = "专注是工作的力量倍增器。我遇到的几乎所有人都会受益于花费更多时间思考应该专注于什么。做正确的事情比工作很多小时更重要。大多数人在不重要的事情上浪费了大部分时间。一旦你确定了要做什么，就要不遗余力地快速完成你的少数几个优先事项。我还没有遇到过一个行动缓慢的人是非常成功的。"
    
    // 用于UI展示的文本
    @State private var inputText: String = ""
    // 用于实际合成的文本
    @State private var currentText: String = ""
    
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showingFilePicker = false
    @State private var referenceAudioPath: String? {
        didSet {
            if let path = referenceAudioPath {
                UserDefaults.standard.set(path, forKey: "LastReferenceAudioPath")
            }
        }
    }
    @State private var referenceText: String = "" {
        didSet {
            UserDefaults.standard.set(referenceText, forKey: "LastReferenceText")
        }
    }
    @State private var showAdvancedSettings = false
    @State private var showSaveSuccess = false  // 添加保存成功提示状态
    
    // 添加状态变化回调
    var onPlayingStateChanged: ((Bool) -> Void)?
    // 添加完成回调
    var onFinishSpeaking: (() -> Void)?
    
    // 合成参数
    @State private var params = GPTSovitsSynthesisParams()
    
    // 在顶部添加新的状态对象
    @StateObject private var playbackManager = AudioPlaybackManager.shared
    
    // 修改保存参数的方法
    private func saveParams() {
        params.saveToUserDefaults()
        showSaveSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSaveSuccess = false
        }
    }
    
    // 修改初始化方法
    init() {
        print("🔵 初始化设置视图，读取保存的参数")
        // 设置默认测试文本
        _inputText = State(initialValue: defaultText)
        _currentText = State(initialValue: defaultText)
        
        // 从 UserDefaults 读取保存的设置
        _referenceAudioPath = State(initialValue: UserDefaults.standard.string(forKey: "LastReferenceAudioPath"))
        _referenceText = State(initialValue: UserDefaults.standard.string(forKey: "LastReferenceText") ?? "")
        
        // 替换原有参数加载逻辑
        let savedParams = GPTSovitsSynthesisParams.loadFromUserDefaults()
        do {
            try savedParams.validate()
            _params = State(initialValue: savedParams)
        } catch {
            print("⚠️ 参数验证失败，使用默认值：\(error.localizedDescription)")
            _params = State(initialValue: GPTSovitsSynthesisParams())
        }
    }
    
    var body: some View {
            Form {
                Section("参考音频设置") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: {
                            showingFilePicker = true
                        }) {
                            HStack {
                                Image(systemName: "music.note")
                                Text(referenceAudioPath == nil ? "选择参考音频" : "更换参考音频")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(playbackManager.isSynthesizing)
                        
                        if let path = referenceAudioPath {
                            Text("已选择音频：\(URL(fileURLWithPath: path).lastPathComponent)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("参考音频文本：")
                                .font(.caption)
                            TextEditor(text: Binding(
                                get: { referenceText },
                                set: { newValue in
                                    referenceText = newValue
                                    UserDefaults.standard.set(newValue, forKey: "LastReferenceText")
                                }
                            ))
                                .frame(height: 60)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2)))
                        }
                    }
                }
            
            Section("测试文本") {
                TextEditor(text: $inputText)
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2)))
                
                HStack(spacing: 20) {
                    // 播放/暂停按钮
                    Button(action: {
                        Task { @MainActor in
                            let refPath = UserDefaults.standard.string(forKey: "LastReferenceAudioPath")
                            let promptText = UserDefaults.standard.string(forKey: "LastReferenceText") ?? ""
                            playbackManager.startPlayback(
                                text: inputText,
                                referencePath: refPath,
                                promptText: promptText
                            )
                        }
                    }) {
                        HStack {
                            if playbackManager.isSynthesizing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: "play.fill")
                            }
                            Text("播放")
                        }
                    }
                    .disabled(playbackManager.isSynthesizing || playbackManager.isPlaying || referenceAudioPath == nil || referenceText.isEmpty)
                    
                    // 新增的停止按钮
                    Button(action: {
                        Task { @MainActor in
                            playbackManager.stopPlayback()
                        }
                    }) {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("停止")
                        }
                    }
                    .disabled(!playbackManager.isPlaying && !playbackManager.isSynthesizing)
                }
            }
            
                Section("高级设置") {
                    Section("文本切分设置") {
                        Picker("切分方法", selection: $params.textSplitMethod) {
                            ForEach(TextSplitMethod.allCases, id: \.self) { method in
                                Text(method.description).tag(method)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        HStack {
                            Text("批处理大小")
                            Slider(value: .init(
                                get: { Double(params.batchSize) },
                                set: { params.batchSize = Int($0) }
                            ), in: Double(ParamRanges.batchSize.lowerBound)...Double(ParamRanges.batchSize.upperBound))
                            Text("\(params.batchSize)")
                        }
                        
                        HStack {
                            Text("批处理阈值")
                            Slider(value: $params.batchThreshold, in: 0.1...1.0)
                            Text(String(format: "%.2f", params.batchThreshold))
                        }
                        
                        Toggle("分桶处理", isOn: $params.splitBucket)
                        Toggle("流式输出", isOn: $params.streamingMode)
                            .help("启用流式输出可以更快开始播放，但可能会有轻微的延迟")
                    }
                    
                    Section("推理参数设置") {
                        HStack {
                            Text("Top-K")
                            Slider(value: .init(
                                get: { Double(params.topK) },
                                set: { params.topK = Int($0) }
                            ), in: Double(ParamRanges.topK.lowerBound)...Double(ParamRanges.topK.upperBound))
                            Text("\(params.topK)")
                        }
                        
                        HStack {
                            Text("Top-P")
                            Slider(value: $params.topP, in: ParamRanges.topP.lowerBound...ParamRanges.topP.upperBound)
                            Text(String(format: "%.2f", params.topP))
                        }
                        
                        HStack {
                            Text("温度系数")
                            Slider(value: $params.temperature, in: ParamRanges.temperature.lowerBound...ParamRanges.temperature.upperBound)
                            Text(String(format: "%.2f", params.temperature))
                        }
                        
                        HStack {
                            Text("重复惩罚")
                            Slider(value: $params.repetitionPenalty, in: ParamRanges.repetitionPenalty.lowerBound...ParamRanges.repetitionPenalty.upperBound)
                            Text(String(format: "%.2f", params.repetitionPenalty))
                        }
                        
                        Toggle("并行推理", isOn: $params.parallelInfer)
                        
                        HStack {
                            Text("语速系数")
                            Slider(value: $params.speedFactor, in: ParamRanges.speedFactor.lowerBound...ParamRanges.speedFactor.upperBound)
                            Text(String(format: "%.2f", params.speedFactor))
                        }
                        
                        HStack {
                            Text("片段间隔")
                            Slider(value: $params.fragmentInterval, in: ParamRanges.fragmentInterval.lowerBound...ParamRanges.fragmentInterval.upperBound)
                            Text(String(format: "%.2f", params.fragmentInterval))
                        }
                    }

                                        HStack {
                        Spacer()
                        Button(action: {
                            // 重置为默认参数
                            params = GPTSovitsSynthesisParams()
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("还原默认设置")
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: saveParams) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("保存参数")
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                    .padding(.bottom, 8)
                    
                    if showSaveSuccess {
                        HStack {
                            Spacer()
                            Text("参数已保存")
                                .foregroundColor(.green)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
            }
            .formStyle(.grouped)
        .alert("错误", isPresented: $showError, actions: {
            Button("确定", role: .cancel) {}
        }, message: {
            Text(errorMessage ?? "未知错误")
        })
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                if let file = files.first {
                    if file.startAccessingSecurityScopedResource() {
                        referenceAudioPath = file.path
                        file.stopAccessingSecurityScopedResource()
                    }
                }
            case .failure(let error):
                errorMessage = "选择音频文件失败：\(error.localizedDescription)"
                showError = true
            }
        }
        // 修改错误处理（可选）
        .onReceive(playbackManager.$errorMessage) { message in
            if let message = message {
                errorMessage = message
                showError = true
            }
        }
    }
}

#Preview {
    GPTSovitsSettingView()
}

