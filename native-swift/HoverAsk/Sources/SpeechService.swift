import AVFoundation
import Foundation
import Speech

enum SpeechServiceError: LocalizedError {
    case speechDenied
    case microphoneDenied
    case recognizerUnavailable
    case microphoneFailed(String)

    var errorDescription: String? {
        switch self {
        case .speechDenied:
            "Speech recognition permission was denied. Enable it in System Settings > Privacy & Security > Speech Recognition."
        case .microphoneDenied:
            "Microphone permission was denied. Enable it in System Settings > Privacy & Security > Microphone."
        case .recognizerUnavailable:
            "Speech recognition is unavailable right now."
        case .microphoneFailed(let message):
            "Could not start microphone: \(message)"
        }
    }
}

final class SpeechService: NSObject {
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    private var silenceTimer: Timer?
    private var maxTimer: Timer?
    private var latestTranscript = ""
    private var didFinish = false
    private var shouldAutoStopOnSilence = true

    var onPartial: ((String) -> Void)?
    var onFinish: ((String) -> Void)?
    var onError: ((String) -> Void)?

    func start(locale: VoiceLocale, autoStopOnSilence: Bool) {
        stop(cancel: true)
        latestTranscript = ""
        didFinish = false
        shouldAutoStopOnSilence = autoStopOnSilence

        requestPermissions { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.startRecognition(locale: locale)
                case .failure(let error):
                    self?.onError?(error.localizedDescription)
                }
            }
        }
    }

    func stopAndSubmit() {
        finish(with: latestTranscript)
    }

    func stop(cancel: Bool = false) {
        silenceTimer?.invalidate()
        silenceTimer = nil
        maxTimer?.invalidate()
        maxTimer = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        if cancel {
            didFinish = true
        }
    }

    private func requestPermissions(_ completion: @escaping (Result<Void, SpeechServiceError>) -> Void) {
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            guard speechStatus == .authorized else {
                completion(.failure(.speechDenied))
                return
            }

            AVCaptureDevice.requestAccess(for: .audio) { micAllowed in
                guard micAllowed else {
                    completion(.failure(.microphoneDenied))
                    return
                }
                completion(.success(()))
            }
        }
    }

    private func startRecognition(locale: VoiceLocale) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale.rawValue))
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            onError?(SpeechServiceError.recognizerUnavailable.localizedDescription)
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            onError?(SpeechServiceError.microphoneFailed(error.localizedDescription).localizedDescription)
            return
        }

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.handle(result: result, error: error)
            }
        }

        maxTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
            self?.finish(with: self?.latestTranscript ?? "")
        }
    }

    private func handle(result: SFSpeechRecognitionResult?, error: Error?) {
        if didFinish {
            return
        }

        if let result {
            let transcript = result.bestTranscription.formattedString
            if !transcript.isEmpty {
                latestTranscript = transcript
                onPartial?(transcript)
                scheduleSilenceStop()
            }

            if result.isFinal {
                finish(with: transcript)
                return
            }
        }

        if let error, !didFinish {
            let nsError = error as NSError
            if nsError.domain == "kAFAssistantErrorDomain" && [1110, 203, 216].contains(nsError.code) {
                finish(with: latestTranscript)
            } else {
                onError?(error.localizedDescription)
                stop(cancel: true)
            }
        }
    }

    private func scheduleSilenceStop() {
        guard shouldAutoStopOnSilence else {
            return
        }

        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.35, repeats: false) { [weak self] _ in
            self?.finish(with: self?.latestTranscript ?? "")
        }
    }

    private func finish(with transcript: String) {
        if didFinish {
            return
        }
        didFinish = true
        let finalText = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        stop(cancel: false)
        onFinish?(finalText)
    }
}

@MainActor
final class SpeechOutput: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var onFinish: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, voice preset: SpeechVoicePreset, rate: Double, onFinish: (() -> Void)? = nil) {
        stop()
        self.onFinish = onFinish
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = Float(min(max(rate, 0.34), 0.58))
        utterance.volume = 0.92
        utterance.pitchMultiplier = 1.03
        utterance.preUtteranceDelay = 0.08
        utterance.voice = speechVoice(for: preset)
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        onFinish = nil
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            let completion = onFinish
            onFinish = nil
            completion?()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            onFinish = nil
        }
    }

    private func speechVoice(for preset: SpeechVoicePreset) -> AVSpeechSynthesisVoice? {
        if let identifier = preset.voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            return voice
        }

        return AVSpeechSynthesisVoice(language: "en-US") ??
            AVSpeechSynthesisVoice(language: "en-IN")
    }
}
