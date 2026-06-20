import AppKit
import Combine
import Foundation

@MainActor
final class OrbViewModel: ObservableObject {
    @Published var phase: OrbPhase = .idle {
        didSet {
            guard !isDismissedByUser else {
                return
            }
            windowController?.apply(phase: phase)
        }
    }
    @Published var transcript = ""
    @Published var answer = ""
    @Published var activeProvider: AssistantProvider?
    @Published var providerHealth: [ProviderHealth] = []
    @Published var companionVisualMotion = CompanionVisualMotion.idle

    let settings: SettingsStore
    let history: HistoryStore

    private let engine = AssistantEngine()
    private let speechService = SpeechService()
    private let speechOutput = SpeechOutput()
    private let motionController: CompanionMotionController
    private weak var windowController: OrbWindowController?
    private var assistantTask: Task<Void, Never>?
    private var interactionToken = UUID()
    private var isDismissedByUser = false
    private var cancellables = Set<AnyCancellable>()

    init(settings: SettingsStore, history: HistoryStore) {
        self.settings = settings
        self.history = history
        self.motionController = CompanionMotionController(settings: settings)
        configureSpeechCallbacks()
        configureMotionCallbacks()
        configureSettingsCallbacks()
        motionController.start()
        refreshHealth()
    }

    func attach(windowController: OrbWindowController) {
        self.windowController = windowController
        motionController.attach(windowController: windowController)
        windowController.apply(phase: phase)
    }

    func primaryOrbAction() {
        switch phase {
        case .idle, .answer, .error:
            startListening()
        case .listening:
            if settings.listenMode == .manualStop {
                stopListeningAndSend()
            }
        case .thinking:
            break
        case .settings:
            collapse()
        }
    }

    func holdBegan() {
        guard settings.listenMode == .holdToTalk else {
            return
        }
        startListening()
    }

    func holdEnded() {
        guard settings.listenMode == .holdToTalk else {
            return
        }
        stopListeningAndSend()
    }

    func startListening() {
        isDismissedByUser = false
        interactionToken = UUID()
        assistantTask?.cancel()
        motionController.pause(for: 1.0)
        speechOutput.stop()
        transcript = ""
        answer = ""
        activeProvider = nil
        phase = .listening

        let autoStop = settings.listenMode != .manualStop
        speechService.start(locale: settings.voiceLocale, autoStopOnSilence: autoStop)
    }

    func stopListeningAndSend() {
        speechService.stopAndSubmit()
    }

    func collapse() {
        isDismissedByUser = false
        interactionToken = UUID()
        assistantTask?.cancel()
        speechService.stop(cancel: true)
        speechOutput.stop()
        motionController.pause(for: 0.8)
        phase = .idle
    }

    func dismissOrb() {
        isDismissedByUser = true
        interactionToken = UUID()
        assistantTask?.cancel()
        speechService.stop(cancel: true)
        speechOutput.stop()
        motionController.pause(for: 1.2)
        phase = .idle
        windowController?.hide()
    }

    func showOrb() {
        isDismissedByUser = false
        windowController?.apply(phase: phase)
    }

    func toggleOrbVisibility() {
        guard let windowController else {
            return
        }
        if windowController.isVisible {
            dismissOrb()
        } else {
            showOrb()
        }
    }

    func quitApp() {
        NSApp.terminate(nil)
    }

    func dragStarted() {
        motionController.pause(for: 2.0)
    }

    func dragEnded() {
        motionController.pause(for: 1.0)
    }

    func openSettings() {
        isDismissedByUser = false
        interactionToken = UUID()
        speechService.stop(cancel: true)
        speechOutput.stop()
        refreshHealth()
        phase = .settings
    }

    func closeSettings() {
        phase = .idle
    }

    func clearHistory() {
        history.clear()
    }

    func retryLastTranscript() {
        let prompt = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            startListening()
            return
        }
        interactionToken = UUID()
        assistantTask?.cancel()
        speechService.stop(cancel: true)
        speechOutput.stop()
        askAssistant(prompt)
    }

    func refreshHealth() {
        Task {
            providerHealth = await engine.healthCheck()
        }
    }

    func login(provider: AssistantProvider) {
        engine.openLogin(provider: provider)
        refreshHealth()
    }

    func previewVoice() {
        speechOutput.speak(
            "Hi, HoverAsk is ready. Ask me in English or Hinglish.",
            voice: settings.speechVoice,
            rate: settings.speechRate
        )
    }

    private func configureSpeechCallbacks() {
        speechService.onPartial = { [weak self] text in
            Task { @MainActor in
                self?.transcript = text
            }
        }

        speechService.onFinish = { [weak self] text in
            Task { @MainActor in
                self?.handleFinalTranscript(text)
            }
        }

        speechService.onError = { [weak self] message in
            Task { @MainActor in
                self?.phase = .error(message)
            }
        }
    }

    private func configureMotionCallbacks() {
        motionController.phaseProvider = { [weak self] in
            self?.phase ?? .idle
        }
        motionController.onVisualMotionChange = { [weak self] motion in
            self?.companionVisualMotion = motion
        }
    }

    private func configureSettingsCallbacks() {
        settings.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.keepPanelVisibleAfterSettingsChange()
                }
            }
            .store(in: &cancellables)
    }

    private func keepPanelVisibleAfterSettingsChange() {
        guard !isDismissedByUser, let windowController else {
            return
        }
        if !settings.avatarStyle.isCompanion {
            companionVisualMotion = .idle
        }
        windowController.apply(phase: phase)
    }

    private func handleFinalTranscript(_ text: String) {
        let finalText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalText.isEmpty else {
            phase = .error("I did not catch anything. Try again closer to the microphone.")
            return
        }

        transcript = finalText
        askAssistant(finalText)
    }

    private func askAssistant(_ prompt: String) {
        phase = .thinking
        let requestToken = interactionToken
        let providerSelection = settings.provider
        let runtimeOptions = settings.providerRuntimeOptions
        assistantTask = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await engine.ask(prompt, provider: providerSelection, options: runtimeOptions)
                if Task.isCancelled { return }
                activeProvider = result.provider
                answer = result.text
                phase = .answer

                if settings.historyEnabled {
                    history.add(prompt: prompt, answer: result.text, provider: result.provider)
                }

                if settings.spokenRepliesEnabled {
                    speechOutput.speak(result.text, voice: settings.speechVoice, rate: settings.speechRate) { [weak self] in
                        self?.continueConversationIfNeeded(token: requestToken)
                    }
                } else {
                    scheduleSilentContinuation(token: requestToken)
                }
            } catch {
                if Task.isCancelled { return }
                phase = .error(error.localizedDescription)
            }
        }
    }

    private func scheduleSilentContinuation(token: UUID) {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 650_000_000)
            await MainActor.run {
                self?.continueConversationIfNeeded(token: token)
            }
        }
    }

    private func continueConversationIfNeeded(token: UUID) {
        guard settings.continuousConversationEnabled,
              interactionToken == token,
              phase == .answer
        else {
            return
        }
        startListening()
    }
}
