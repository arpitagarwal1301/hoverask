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
    @Published var typedPrompt = ""
    @Published var currentSubmittedQuestion = ""
    @Published var currentAnswer = ""
    @Published var sessionExchanges: [SessionExchange] = []
    @Published var inputStatusMessage = ""
    @Published var isChatExpanded = false
    @Published var activeProvider: AssistantProvider?
    @Published var providerHealth: [ProviderHealth] = []
    @Published var isRefreshingProviderHealth = false
    @Published var providerHealthLastRefreshed: Date?
    @Published var providerTestResults: [AssistantProvider: ProviderTestResult] = [:]
    @Published var providerModelOptions: [AssistantProvider: [String]] = [:]
    @Published var companionVisualMotion = CompanionVisualMotion.idle
    @Published var hotKeyRegistrationMessage = ""
    @Published var microphoneTestState: VoiceTestState = .idle
    @Published var speechRecognitionTestState: VoiceTestState = .idle

    let settings: SettingsStore
    let history: HistoryStore

    private let engine = AssistantEngine()
    private let speechService = SpeechService()
    private let speechOutput = SpeechOutput()
    private let microphoneTester = MicrophoneLevelTester()
    private let speechRecognitionTester = SpeechRecognitionTester()
    private let motionController: CompanionMotionController
    private weak var windowController: OrbWindowController?
    private weak var settingsWindowController: SettingsWindowController?
    private var assistantTask: Task<Void, Never>?
    private var interactionToken = UUID()
    private var activeExchangeID: UUID?
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

    func attach(settingsWindowController: SettingsWindowController) {
        self.settingsWindowController = settingsWindowController
    }

    func primaryOrbAction() {
        switch phase {
        case .idle:
            startListening()
        case .chat, .listening, .thinking, .answer, .error:
            collapse()
        case .settings:
            closeSettings()
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
        guard phase != .thinking else {
            return
        }
        isDismissedByUser = false
        interactionToken = UUID()
        assistantTask?.cancel()
        activeExchangeID = nil
        motionController.pause(for: 1.0)
        speechOutput.stop()
        typedPrompt = ""
        inputStatusMessage = ""
        phase = .listening

        let autoStop = settings.listenMode != .manualStop
        speechService.start(locale: settings.voiceLocale, autoStopOnSilence: autoStop)
    }

    func openChat() {
        startListening()
    }

    func stopListeningAndSend() {
        speechService.stopAndSubmit()
    }

    func stopListeningWithoutSubmitting() {
        speechService.stop(cancel: true)
        typedPrompt = ""
        inputStatusMessage = ""
        phase = currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .chat : .answer
    }

    func updateTypedPromptFromUser(_ text: String) {
        if phase == .listening {
            speechService.stop(cancel: true)
            inputStatusMessage = ""
            phase = currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .chat : .answer
        }
        typedPrompt = text
    }

    func toggleSpokenReplies() {
        settings.spokenRepliesEnabled.toggle()
        if !settings.spokenRepliesEnabled {
            speechOutput.stop()
        }
    }

    func submitTypedPrompt() {
        let prompt = typedPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            return
        }

        interactionToken = UUID()
        assistantTask?.cancel()
        speechService.stop(cancel: true)
        speechOutput.stop()
        typedPrompt = ""
        submitPrompt(prompt)
    }

    func collapse() {
        isDismissedByUser = false
        interactionToken = UUID()
        assistantTask?.cancel()
        speechService.stop(cancel: true)
        speechOutput.stop()
        typedPrompt = ""
        inputStatusMessage = ""
        isChatExpanded = false
        motionController.pause(for: 0.8)
        phase = .idle
    }

    func dismissOrb() {
        isDismissedByUser = true
        interactionToken = UUID()
        assistantTask?.cancel()
        activeExchangeID = nil
        speechService.stop(cancel: true)
        speechOutput.stop()
        motionController.pause(for: 1.2)
        phase = .idle
        isChatExpanded = false
        windowController?.hide()
    }

    func showOrb() {
        isDismissedByUser = false
        windowController?.centerOnVisibleScreen()
        windowController?.apply(phase: phase)
    }

    func toggleChatFromShortcut() {
        guard let windowController else {
            showOrb()
            startListening()
            return
        }
        if !windowController.isVisible {
            showOrb()
            startListening()
            return
        }
        switch phase {
        case .idle:
            startListening()
        case .chat, .listening, .thinking, .answer, .error:
            collapse()
        case .settings:
            closeSettings()
            phase = .idle
        }
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
        typedPrompt = ""
        inputStatusMessage = ""
        refreshHealth()
        if phase == .listening {
            phase = currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .chat : .answer
        }
        if phase == .settings {
            phase = .idle
        }
        settingsWindowController?.show()
    }

    func closeSettings() {
        settingsWindowController?.hide()
        if phase == .settings {
            phase = .idle
        }
    }

    func clearHistory() {
        history.clear()
    }

    func retryLastTranscript() {
        let prompt = currentSubmittedQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            startListening()
            return
        }
        interactionToken = UUID()
        assistantTask?.cancel()
        speechService.stop(cancel: true)
        speechOutput.stop()
        submitPrompt(prompt)
    }

    func refreshHealth() {
        guard !isRefreshingProviderHealth else {
            return
        }
        isRefreshingProviderHealth = true
        Task {
            providerHealth = await engine.healthCheck()
            providerHealthLastRefreshed = Date()
            isRefreshingProviderHealth = false
        }
    }

    func login(provider: AssistantProvider) {
        settings.setProviderDisabled(false, provider: provider)
        engine.openLogin(provider: provider)
        refreshHealth()
    }

    func saveBYOKKey(_ key: String, for provider: AssistantProvider) {
        do {
            try BYOKKeychain.save(key, for: provider)
            settings.setProviderDisabled(false, provider: provider)
            providerTestResults[provider] = ProviderTestResult(provider: provider, success: true, message: "Key saved in macOS Keychain.", duration: nil)
            refreshHealth()
            fetchModels(for: provider)
        } catch {
            providerTestResults[provider] = ProviderTestResult(provider: provider, success: false, message: error.localizedDescription, duration: nil)
        }
    }

    func deleteBYOKKey(for provider: AssistantProvider) {
        do {
            try BYOKKeychain.delete(for: provider)
            providerModelOptions[provider] = []
            providerTestResults[provider] = ProviderTestResult(provider: provider, success: true, message: "Key removed from Keychain.", duration: nil)
            refreshHealth()
        } catch {
            providerTestResults[provider] = ProviderTestResult(provider: provider, success: false, message: error.localizedDescription, duration: nil)
        }
    }

    func disconnectProvider(_ provider: AssistantProvider) {
        settings.setProviderDisabled(true, provider: provider)
        providerTestResults[provider] = ProviderTestResult(provider: provider, success: true, message: "\(provider.title) disconnected from HoverAsk routing.", duration: nil)
        refreshHealth()
    }

    func reconnectProvider(_ provider: AssistantProvider) {
        settings.setProviderDisabled(false, provider: provider)
        providerTestResults[provider] = ProviderTestResult(provider: provider, success: true, message: "\(provider.title) enabled for HoverAsk routing.", duration: nil)
        refreshHealth()
    }

    func testProvider(_ provider: AssistantProvider) {
        providerTestResults[provider] = ProviderTestResult(provider: provider, success: false, message: "Testing...", duration: nil)
        Task {
            let result = await engine.testProvider(provider, options: settings.providerRuntimeOptions)
            providerTestResults[provider] = result
            refreshHealth()
        }
    }

    func fetchModels(for provider: AssistantProvider) {
        Task {
            do {
                let models = try await engine.fetchModels(provider: provider)
                providerModelOptions[provider] = models
                if let first = models.first {
                    applyFetchedModel(first, for: provider)
                }
            } catch {
                providerTestResults[provider] = ProviderTestResult(provider: provider, success: false, message: error.localizedDescription, duration: nil)
            }
        }
    }

    func previewVoice() {
        speechOutput.speak(
            "Hi, HoverAsk is ready. Ask me in English or Hinglish.",
            voice: settings.speechVoice,
            rate: settings.speechRate
        )
    }

    func testMicrophone() {
        microphoneTester.stop()
        microphoneTestState = .testing("Requesting microphone")
        microphoneTester.start { [weak self] level in
            self?.microphoneTestState = .microphoneLevel(level)
        } completion: { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success:
                    self?.microphoneTestState = .testing("Speak now")
                    Task { @MainActor [weak self] in
                        try? await Task.sleep(nanoseconds: 5_200_000_000)
                        if case .microphoneLevel = self?.microphoneTestState {
                            self?.microphoneTestState = .passed("Microphone works")
                        } else if case .testing = self?.microphoneTestState {
                            self?.microphoneTestState = .passed("Microphone allowed")
                        }
                    }
                case .failure(let error):
                    self?.microphoneTestState = .failed(error.localizedDescription)
                }
            }
        }
    }

    func testSpeechRecognition() {
        speechRecognitionTester.stop(cancel: true)
        speechRecognitionTestState = .testing("Listening for test phrase")
        speechRecognitionTester.start(locale: settings.voiceLocale) { [weak self] transcript in
            self?.speechRecognitionTestState = .testing(transcript)
        } completion: { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let transcript):
                    let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                    self?.speechRecognitionTestState = trimmed.isEmpty
                        ? .failed("No speech detected")
                        : .passed(trimmed)
                case .failure(let error):
                    self?.speechRecognitionTestState = .failed(error.localizedDescription)
                }
            }
        }
    }

    func updateHotKeyRegistration(success: Bool) {
        hotKeyRegistrationMessage = success ? "Shortcut active." : "macOS rejected this shortcut. Try another combination."
    }

    private func applyFetchedModel(_ model: String, for provider: AssistantProvider) {
        settings.setProviderModelID(model, for: provider)
        switch provider {
        case .ollama:
            if settings.ollamaModel == AssistantProvider.ollama.defaultModel {
                settings.ollamaModel = model
            }
        case .lmStudio:
            if settings.lmStudioModel == AssistantProvider.lmStudio.defaultModel {
                settings.lmStudioModel = model
            }
        case .openAI:
            if settings.openAIModel == AssistantProvider.openAI.defaultModel {
                settings.openAIModel = model
            }
        case .anthropic:
            if settings.anthropicModel == AssistantProvider.anthropic.defaultModel {
                settings.anthropicModel = model
            }
        case .gemini:
            if settings.geminiModel == AssistantProvider.gemini.defaultModel {
                settings.geminiModel = model
            }
        case .openRouter:
            if settings.openRouterModel == AssistantProvider.openRouter.defaultModel {
                settings.openRouterModel = model
            }
        case .groq:
            if settings.groqModel == AssistantProvider.groq.defaultModel {
                settings.groqModel = model
            }
        case .codex, .claude, .cursor, .opencode, .antigravity, .appleIntelligence:
            break
        }
    }

    private func configureSpeechCallbacks() {
        speechService.onPartial = { [weak self] text in
            Task { @MainActor in
                self?.typedPrompt = text
                self?.inputStatusMessage = ""
            }
        }

        speechService.onFinish = { [weak self] text in
            Task { @MainActor in
                self?.handleFinalTranscript(text)
            }
        }

        speechService.onError = { [weak self] message in
            Task { @MainActor in
                self?.handleListeningError(message)
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
            typedPrompt = ""
            inputStatusMessage = "Didn't catch that."
            phase = currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .chat : .answer
            return
        }

        typedPrompt = ""
        submitPrompt(finalText)
    }

    private func handleListeningError(_ message: String) {
        typedPrompt = ""
        inputStatusMessage = message
        phase = currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .chat : .answer
    }

    private func submitPrompt(_ prompt: String) {
        inputStatusMessage = ""
        currentSubmittedQuestion = prompt
        transcript = prompt
        let exchangeID = UUID()
        activeExchangeID = exchangeID
        sessionExchanges.append(
            SessionExchange(
                id: exchangeID,
                question: prompt,
                answer: "",
                provider: nil,
                status: .pending
            )
        )
        askAssistant(prompt, exchangeID: exchangeID)
    }

    private func askAssistant(_ prompt: String, exchangeID: UUID) {
        phase = .thinking
        let requestToken = interactionToken
        let providerSelection = settings.provider
        let runtimeOptions = settings.providerRuntimeOptions
        assistantTask = Task { [weak self] in
            guard let self else { return }
            do {
                let context = sessionExchanges.filter { $0.id != exchangeID }
                let result = try await engine.ask(prompt, provider: providerSelection, options: runtimeOptions, sessionContext: context)
                if Task.isCancelled { return }
                activeProvider = result.provider
                answer = result.text
                currentAnswer = result.text
                updateSessionExchange(id: exchangeID, answer: result.text, provider: result.provider, status: .answered)
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
                updateSessionExchange(id: exchangeID, answer: "", provider: nil, status: .failed(error.localizedDescription))
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

    private func updateSessionExchange(id: UUID, answer: String, provider: AssistantProvider?, status: SessionExchangeStatus) {
        guard let index = sessionExchanges.firstIndex(where: { $0.id == id }) else {
            return
        }
        sessionExchanges[index].answer = answer
        sessionExchanges[index].provider = provider
        sessionExchanges[index].status = status
    }
}
