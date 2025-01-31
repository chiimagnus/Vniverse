// 实现的主要功能：

// 1. **文本切分方法**：
// 通过 `TextSplitMethod` 枚举提供了6种文本切分方式：
// - 不切分
// - 每四句话切分一次
// - 每50个字符切分一次
// - 按中文句号切分
// - 按英文句号切分
// - 按标点符号切分

// 2. **语音合成参数配置**：
// `GPTSovitsSynthesisParams` 结构体包含了丰富的合成参数：
// - 文本切分设置
// - 批量处理参数
// - 推理参数（如温度、重复惩罚等）
// - 语音速度因子
// - 流式输出控制

// 3. **音频流播放器**：
// `AudioStreamPlayer` 类实现了实时音频流播放功能：
// - 支持WAV格式音频解析
// - 实现了音频引擎管理
// - 提供了音频数据缓冲和播放控制

// 4. **核心功能实现**：
// `GPTSovits` actor类提供了两种主要的语音合成方式：

// a) **普通合成模式** (`synthesize` 方法)：
// b) **流式合成模式** (`synthesizeStream` 方法)：

// 5. **音频播放控制**：
// 提供了完整的音频播放控制功能：
// - 播放（`play`）
// - 暂停（`pause`）
// - 恢复（`resume`）
// - 停止（`stop`）

// 6. **网络通信**：
// - 与本地服务器（`http://127.0.0.1:9880`）通信
// - 支持HTTP请求参数配置
// - 实现了服务器状态检查

// 7. **性能优化**：
// - 实现了音频数据缓冲机制
// - 支持并行推理
// - 提供了批量处理能力


import Foundation
import AVFoundation

// 参数范围限制
public struct ParamRanges {
    public static let batchSize = 1...200
    public static let fragmentInterval = 0.01...1.0
    public static let topK = 1...100
    public static let topP = 0.01...1.0
    public static let temperature = 0.01...1.0
    public static let repetitionPenalty = 0.0...2.0
    public static let speedFactor = 0.01...2.0
}

// 错误类型定义
public enum GPTSovitsError: LocalizedError {
    case serverNotAvailable
    case synthesisError(String)
    case playbackError
    case invalidResponse
    case configurationError(String)
    case invalidParameter(String)
    
    public var errorDescription: String? {
        switch self {
        case .serverNotAvailable:
            return "无法连接到服务器，请检查网络连接或服务器状态"
        case .synthesisError(let message):
            return "语音合成失败：\(message)"
        case .playbackError:
            return "音频播放失败，请检查音频格式或系统音频设置"
        case .invalidResponse:
            return "服务器返回的响应格式无效"
        case .configurationError(let message):
            return "配置错误：\(message)"
        case .invalidParameter(let message):
            return "参数错误：\(message)"
        }
    }
}

// 文本切分方法
public enum TextSplitMethod: String, CaseIterable {
    case noSplit = "cut0"      // 不切分
    case fourSentences = "cut1" // 凑四句一切
    case fiftyChars = "cut2"   // 凑50字一切
    case chinesePeriod = "cut3" // 按中文句号。切
    case englishPeriod = "cut4" // 按英文句号.切
    case punctuation = "cut5"   // 按标点符号切
    
    public var description: String {
        switch self {
        case .noSplit: return "不切分"
        case .fourSentences: return "凑四句一切"
        case .fiftyChars: return "凑50字一切"
        case .chinesePeriod: return "按中文句号切"
        case .englishPeriod: return "按英文句号切"
        case .punctuation: return "按标点符号切"
        }
    }
}

// 合成参数设置
public struct GPTSovitsSynthesisParams {
    // 文本切分设置
    public var textSplitMethod: TextSplitMethod = .punctuation
    public var batchSize: Int = 1
    public var batchThreshold: Double = 0.75
    public var splitBucket: Bool = true
    
    // 推理参数
    public var topK: Int = 5
    public var topP: Double = 1.0
    public var temperature: Double = 1.0
    public var repetitionPenalty: Double = 1.35
    public var parallelInfer: Bool = true
    public var speedFactor: Double = 1.0
    public var fragmentInterval: Double = 0.3
    
    // 流式输出
    public var streamingMode: Bool = true
    
    public init() {}
    
    // 参数范围验证
    public func validate() throws {
        if !ParamRanges.batchSize.contains(batchSize) {
            throw GPTSovitsError.invalidParameter("批量大小必须在 \(ParamRanges.batchSize.lowerBound) 到 \(ParamRanges.batchSize.upperBound) 之间")
        }
        if !ParamRanges.topK.contains(topK) {
            throw GPTSovitsError.invalidParameter("top_k 必须在 \(ParamRanges.topK.lowerBound) 到 \(ParamRanges.topK.upperBound) 之间")
        }
        if !ParamRanges.topP.contains(topP) {
            throw GPTSovitsError.invalidParameter("top_p 必须在 \(ParamRanges.topP.lowerBound) 到 \(ParamRanges.topP.upperBound) 之间")
        }
        if !ParamRanges.temperature.contains(temperature) {
            throw GPTSovitsError.invalidParameter("temperature 必须在 \(ParamRanges.temperature.lowerBound) 到 \(ParamRanges.temperature.upperBound) 之间")
        }
        if !ParamRanges.repetitionPenalty.contains(repetitionPenalty) {
            throw GPTSovitsError.invalidParameter("repetition_penalty 必须在 \(ParamRanges.repetitionPenalty.lowerBound) 到 \(ParamRanges.repetitionPenalty.upperBound) 之间")
        }
        if !ParamRanges.speedFactor.contains(speedFactor) {
            throw GPTSovitsError.invalidParameter("speed_factor 必须在 \(ParamRanges.speedFactor.lowerBound) 到 \(ParamRanges.speedFactor.upperBound) 之间")
        }
        if !ParamRanges.fragmentInterval.contains(fragmentInterval) {
            throw GPTSovitsError.invalidParameter("fragment_interval 必须在 \(ParamRanges.fragmentInterval.lowerBound) 到 \(ParamRanges.fragmentInterval.upperBound) 之间")
        }
    }
    
    // 统一保存到 UserDefaults
    func saveToUserDefaults() {
        print("🔵 保存参数设置到 UserDefaults")
        UserDefaults.standard.set(textSplitMethod.rawValue, forKey: "TextSplitMethod")
        UserDefaults.standard.set(batchSize, forKey: "BatchSize")
        UserDefaults.standard.set(batchThreshold, forKey: "BatchThreshold")
        UserDefaults.standard.set(splitBucket, forKey: "SplitBucket")
        UserDefaults.standard.set(streamingMode, forKey: "StreamingMode")
        UserDefaults.standard.set(topK, forKey: "TopK")
        UserDefaults.standard.set(topP, forKey: "TopP")
        UserDefaults.standard.set(temperature, forKey: "Temperature")
        UserDefaults.standard.set(repetitionPenalty, forKey: "RepetitionPenalty")
        UserDefaults.standard.set(parallelInfer, forKey: "ParallelInfer")
        UserDefaults.standard.set(speedFactor, forKey: "SpeedFactor")
        UserDefaults.standard.set(fragmentInterval, forKey: "FragmentInterval")
    }
    
    // 统一从 UserDefaults 加载
    static func loadFromUserDefaults() -> GPTSovitsSynthesisParams {
        print("🔵 从 UserDefaults 加载参数")
        var params = GPTSovitsSynthesisParams()
        
        // 文本切分方法
        if let methodRawValue = UserDefaults.standard.string(forKey: "TextSplitMethod"),
           let method = TextSplitMethod(rawValue: methodRawValue) {
            params.textSplitMethod = method
        }
        
        // 数值参数
        params.batchSize = UserDefaults.standard.integer(forKey: "BatchSize")
        params.batchThreshold = UserDefaults.standard.double(forKey: "BatchThreshold")
        params.topK = UserDefaults.standard.integer(forKey: "TopK")
        params.topP = UserDefaults.standard.double(forKey: "TopP")
        params.temperature = UserDefaults.standard.double(forKey: "Temperature")
        params.repetitionPenalty = UserDefaults.standard.double(forKey: "RepetitionPenalty")
        params.speedFactor = UserDefaults.standard.double(forKey: "SpeedFactor")
        params.fragmentInterval = UserDefaults.standard.double(forKey: "FragmentInterval")
        
        // 布尔值参数
        params.splitBucket = UserDefaults.standard.bool(forKey: "SplitBucket")
        params.streamingMode = UserDefaults.standard.bool(forKey: "StreamingMode")
        params.parallelInfer = UserDefaults.standard.bool(forKey: "ParallelInfer")
        
        return params
    }
}

// 音频流播放器
class AudioStreamPlayer {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let bufferSize = 4096
    private var isPlaying = false
    private let audioFormat: AVAudioFormat
    private let parsingQueue = DispatchQueue(label: "com.voiceuniverse.audio.parsing")
    private var pendingData = Data()
    private var isWAVHeaderParsed = false
    private var wavHeaderOffset = 0
    
    init() {
        // 设置默认音频格式（可能会被WAV头信息覆盖）
        audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                  sampleRate: 44100,
                                  channels: 1,
                                  interleaved: false)!
        
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFormat)
        
        do {
            try engine.start()
            playerNode.play()
        } catch {
            print("🔴 音频引擎启动失败：\(error.localizedDescription)")
        }
    }
    
    func play(_ data: Data) {
        parsingQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.pendingData.append(data)
            
            // 如果还没有解析WAV头，先解析
            if !self.isWAVHeaderParsed && self.pendingData.count >= 44 {
                self.parseWAVHeader()
            }
            
            // 处理音频数据
            self.processAudioData()
        }
    }
    
    private func parseWAVHeader() {
        // WAV文件头解析
        guard pendingData.count >= 44 else { return }
        
        // 检查WAV文件标识符
        let riffHeader = pendingData.prefix(4)
        guard String(data: riffHeader, encoding: .ascii) == "RIFF" else {
            print("🔴 无效的WAV文件头")
            return
        }
        
        // 解析采样率（字节44-47）
        let sampleRateData = pendingData[24..<28]
        let sampleRate = sampleRateData.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        // 解析通道数（字节22-23）
        let channelsData = pendingData[22..<24]
        let channels = channelsData.withUnsafeBytes { $0.load(as: UInt16.self) }
        
        // 解析位深度（字节34-35）
        let bitsPerSampleData = pendingData[34..<36]
        let bitsPerSample = bitsPerSampleData.withUnsafeBytes { $0.load(as: UInt16.self) }
        
        print("🟢 WAV头解析结果：")
        print("采样率: \(sampleRate)Hz")
        print("通道数: \(channels)")
        print("位深度: \(bitsPerSample)位")
        
        // 更新音频格式
        if let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                    sampleRate: Double(sampleRate),
                                    channels: AVAudioChannelCount(channels),
                                    interleaved: false) {
            // 重新配置音频引擎
            engine.stop()
            engine.reset()
            engine.attach(playerNode)
            engine.connect(playerNode, to: engine.mainMixerNode, format: format)
            try? engine.start()
            playerNode.play()
        }
        
        // 标记WAV头已解析，并记录数据偏移
        isWAVHeaderParsed = true
        wavHeaderOffset = 44  // 标准WAV头长度
        
        // 移除WAV头数据
        pendingData = pendingData.subdata(in: wavHeaderOffset..<pendingData.count)
    }
    
    private func processAudioData() {
        // 如果还没解析WAV头，等待更多数据
        guard isWAVHeaderParsed else { return }
        
        // 确保有足够的数据可以处理
        let frameSize = 2  // 16位采样
        let framesPerBuffer = 1024
        let bytesPerBuffer = framesPerBuffer * frameSize
        
        while pendingData.count >= bytesPerBuffer {
            // 提取一个缓冲区的数据
            let chunkData = pendingData.prefix(bytesPerBuffer)
            pendingData = pendingData.subdata(in: bytesPerBuffer..<pendingData.count)
            
            // 创建音频缓冲区
            guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat,
                                              frameCapacity: AVAudioFrameCount(framesPerBuffer)) else {
                continue
            }
            
            buffer.frameLength = buffer.frameCapacity
            
            // 将数据复制到缓冲区
            chunkData.withUnsafeBytes { _ in
                let buf = UnsafeMutableBufferPointer(start: buffer.floatChannelData?[0],
                                                   count: framesPerBuffer)
                
                // 将16位整数转换为浮点数
                for i in 0..<framesPerBuffer {
                    if i * 2 + 1 < chunkData.count {
                        let sample = Int16(chunkData[i * 2]) | (Int16(chunkData[i * 2 + 1]) << 8)
                        buf[i] = Float(sample) / Float(Int16.max)
                    }
                }
            }
            
            // 调度缓冲区播放
            playerNode.scheduleBuffer(buffer) { [weak self] in
                self?.isPlaying = false
            }
            
            if !playerNode.isPlaying {
                playerNode.play()
            }
            isPlaying = true
        }
    }
    
    func stop() {
        parsingQueue.async { [weak self] in
            self?.playerNode.stop()
            self?.engine.stop()
            self?.pendingData.removeAll()
            self?.isWAVHeaderParsed = false
            self?.isPlaying = false
        }
    }
    
    func isCurrentlyPlaying() -> Bool {
        return isPlaying
    }
    
    deinit {
        stop()
    }
}

actor GPTSovits {
    // 单例模式
    static let shared = GPTSovits()
    
    // 服务配置
    private let baseURL = "http://127.0.0.1:9880"
    private var audioPlayer: AVAudioPlayer?
    
    // 当前播放状态
    private(set) var isPlaying = false
    private(set) var isPaused = false
    
    private var streamPlayer: AudioStreamPlayer?
    
    // 文本转语音
    func synthesize(
        text: String,
        referenceAudioPath: String? = nil,
        promptText: String? = nil,
        params: GPTSovitsSynthesisParams = GPTSovitsSynthesisParams(),
        maxRetries: Int = 3
    ) async throws -> Data {
        // 验证参数
        try params.validate()
        
        // 构建请求URL和参数
        let urlString = "\(baseURL)/tts"
        var urlComponents = URLComponents(string: urlString)!
        
        // 设置查询参数
        urlComponents.queryItems = [
            URLQueryItem(name: "text", value: text),
            URLQueryItem(name: "text_lang", value: "zh"),
            URLQueryItem(name: "ref_audio_path", value: referenceAudioPath ?? ""),
            URLQueryItem(name: "prompt_lang", value: "zh"),
            URLQueryItem(name: "prompt_text", value: promptText ?? "这是一个测试音频"),
            URLQueryItem(name: "text_split_method", value: params.textSplitMethod.rawValue),
            URLQueryItem(name: "batch_size", value: String(params.batchSize)),
            URLQueryItem(name: "batch_threshold", value: String(params.batchThreshold)),
            URLQueryItem(name: "split_bucket", value: String(params.splitBucket)),
            URLQueryItem(name: "top_k", value: String(params.topK)),
            URLQueryItem(name: "top_p", value: String(params.topP)),
            URLQueryItem(name: "temperature", value: String(params.temperature)),
            URLQueryItem(name: "repetition_penalty", value: String(params.repetitionPenalty)),
            URLQueryItem(name: "parallel_infer", value: String(params.parallelInfer)),
            URLQueryItem(name: "speed_factor", value: String(params.speedFactor)),
            URLQueryItem(name: "fragment_interval", value: String(params.fragmentInterval)),
            URLQueryItem(name: "streaming_mode", value: "false"),
            URLQueryItem(name: "media_type", value: "wav")
        ]
        
        guard let url = urlComponents.url else {
            throw GPTSovitsError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 180  // 设置3分钟超时
        
        print("🔵 准备发送合成请求：\(url)")
        print("🔵 检查本地服务是否运行...")
        
        // 首先检查服务是否可用
        do {
            let testURL = URL(string: "\(baseURL)")!
            var testRequest = URLRequest(url: testURL)
            testRequest.timeoutInterval = 5  // 设置较短的超时时间用于测试
            
            let (_, response) = try await URLSession.shared.data(for: testRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("🔴 无法连接到本地服务，请确保已运行 go-api.command")
                throw GPTSovitsError.serverNotAvailable
            }
            print("🟢 本地服务响应状态码：\(httpResponse.statusCode)")
        } catch {
            print("🔴 连接本地服务失败：\(error.localizedDescription)")
            print("🔴 请确保已运行 go-api.command 并且服务正常启动")
            throw GPTSovitsError.serverNotAvailable
        }
        
        var lastError: Error? = nil
        for retryCount in 0..<maxRetries {
            do {
                print("🔵 第\(retryCount + 1)次尝试发送请求...")
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw GPTSovitsError.serverNotAvailable
                }
                
                print("🟡 服务器响应状态码：\(httpResponse.statusCode)")
                
                // 打印响应内容以便调试
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🟡 服务器响应内容：\(responseString)")
                }
                
                if httpResponse.statusCode == 200 {
                    print("🟢 成功获取音频数据")
                    return data
                } else {
                    if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = errorJson["message"] as? String {
                        throw GPTSovitsError.synthesisError(message)
                    } else {
                        throw GPTSovitsError.synthesisError("未知错误")
                    }
                }
            } catch {
                lastError = error
                print("🔴 第\(retryCount + 1)次尝试失败：\(error.localizedDescription)")
                
                if retryCount < maxRetries - 1 {
                    let delay = Double(retryCount + 1) * 2.0
                    print("⏳ 等待 \(delay) 秒后重试...")
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            }
        }
        
        throw lastError ?? GPTSovitsError.synthesisError("所有重试都失败了")
    }
    
    // 文本转语音（流式输出）
    func synthesizeStream(
        text: String,
        referenceAudioPath: String? = nil,
        promptText: String? = nil,
        params: GPTSovitsSynthesisParams = GPTSovitsSynthesisParams(),
        maxRetries: Int = 3
    ) async throws -> AsyncThrowingStream<Data, Error> {
        // 验证参数
        try params.validate()
        
        // 构建请求URL和参数
        let urlString = "\(baseURL)/tts"
        var urlComponents = URLComponents(string: urlString)!
        
        // 设置查询参数
        var modifiedParams = params
        modifiedParams.streamingMode = true  // 强制启用流式输出
        
        urlComponents.queryItems = [
            URLQueryItem(name: "text", value: text),
            URLQueryItem(name: "text_lang", value: "zh"),
            URLQueryItem(name: "ref_audio_path", value: referenceAudioPath ?? ""),
            URLQueryItem(name: "prompt_lang", value: "zh"),
            URLQueryItem(name: "prompt_text", value: promptText ?? "这是一个测试音频"),
            URLQueryItem(name: "text_split_method", value: modifiedParams.textSplitMethod.rawValue),
            URLQueryItem(name: "batch_size", value: String(modifiedParams.batchSize)),
            URLQueryItem(name: "batch_threshold", value: String(modifiedParams.batchThreshold)),
            URLQueryItem(name: "split_bucket", value: String(modifiedParams.splitBucket)),
            URLQueryItem(name: "top_k", value: String(modifiedParams.topK)),
            URLQueryItem(name: "top_p", value: String(modifiedParams.topP)),
            URLQueryItem(name: "temperature", value: String(modifiedParams.temperature)),
            URLQueryItem(name: "repetition_penalty", value: String(modifiedParams.repetitionPenalty)),
            URLQueryItem(name: "parallel_infer", value: String(modifiedParams.parallelInfer)),
            URLQueryItem(name: "speed_factor", value: String(modifiedParams.speedFactor)),
            URLQueryItem(name: "fragment_interval", value: String(modifiedParams.fragmentInterval)),
            URLQueryItem(name: "streaming_mode", value: "true"),
            URLQueryItem(name: "media_type", value: "wav")
        ]
        
        guard let url = urlComponents.url else {
            throw GPTSovitsError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 180  // 设置3分钟超时
        
        print("🔵 准备发送流式合成请求：\(url)")
        
        // 创建一个异步流
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw GPTSovitsError.serverNotAvailable
                    }
                    
                    if httpResponse.statusCode != 200 {
                        throw GPTSovitsError.synthesisError("服务器返回错误：\(httpResponse.statusCode)")
                    }
                    
                    print("🟢 开始接收音频流...")
                    
                    var buffer = Data()
                    let chunkSize = 4096  // 设置合适的缓冲区大小
                    
                    for try await byte in bytes {
                        buffer.append(byte)
                        
                        // 当缓冲区达到指定大小时发送数据
                        if buffer.count >= chunkSize {
                            continuation.yield(buffer)
                            buffer = Data()
                        }
                    }
                    
                    // 发送剩余的数据
                    if !buffer.isEmpty {
                        continuation.yield(buffer)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // 播放音频数据
    func play(_ audioData: Data) async throws {
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.prepareToPlay()
            
            guard audioPlayer?.play() == true else {
                throw GPTSovitsError.playbackError
            }
            
            updatePlaybackState(playing: true, paused: false)
        } catch {
            throw GPTSovitsError.playbackError
        }
    }
    
    // 暂停播放
    func pause() {
        audioPlayer?.pause()
        updatePlaybackState(playing: false, paused: true)
    }
    
    // 恢复播放
    func resume() {
        audioPlayer?.play()
        updatePlaybackState(playing: true, paused: false)
    }
    
    // 停止播放
    func stop() {
        audioPlayer?.stop()
        streamPlayer?.stop()
        updatePlaybackState(playing: false, paused: false)
    }
    
    // 播放流式音频数据
    func playStream(_ audioStream: AsyncThrowingStream<Data, Error>) async throws {
        // 停止当前播放
        stop()
        
        // 创建新的播放器
        streamPlayer = AudioStreamPlayer()
        
        do {
            var isFirstChunk = true
            var totalBytes = 0
            
            for try await chunk in audioStream {
                if Task.isCancelled {
                    throw GPTSovitsError.playbackError
                }
                
                guard let player = streamPlayer else {
                    throw GPTSovitsError.playbackError
                }
                
                if isFirstChunk {
                    print("🟢 收到第一个音频块，大小：\(chunk.count)字节")
                    isFirstChunk = false
                }
                
                totalBytes += chunk.count
                
                // 确保播放操作在主线程
                await MainActor.run {
                    player.play(chunk)
                }
            }
            
            print("🟢 音频流接收完成，总共接收：\(totalBytes) 字节")
            
            // 更新状态时直接调用同步方法
            updatePlaybackState(playing: true, paused: false)
            
            // 等待一段时间确保所有音频都播放完成
            try await Task.sleep(nanoseconds: 1_000_000_000)  // 1秒
            
        } catch {
            print("🔴 音频流播放失败：\(error.localizedDescription)")
            streamPlayer?.stop()
            streamPlayer = nil
            updatePlaybackState(playing: false, paused: false)
            throw error
        }
    }
    
    // 修改状态更新方法为同步
    private func updatePlaybackState(playing: Bool, paused: Bool) {
        isPlaying = playing
        isPaused = paused
    }
}
