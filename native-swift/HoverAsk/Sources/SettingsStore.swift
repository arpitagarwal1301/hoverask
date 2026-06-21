import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    @Published var provider: ProviderSelection {
        didSet { defaults.set(provider.rawValue, forKey: Keys.provider) }
    }

    @Published var voiceLocale: VoiceLocale {
        didSet { defaults.set(voiceLocale.rawValue, forKey: Keys.voiceLocale) }
    }

    @Published var speechVoice: SpeechVoicePreset {
        didSet { defaults.set(speechVoice.rawValue, forKey: Keys.speechVoice) }
    }

    @Published var speechRate: Double {
        didSet { defaults.set(speechRate, forKey: Keys.speechRate) }
    }

    @Published var listenMode: ListenMode {
        didSet { defaults.set(listenMode.rawValue, forKey: Keys.listenMode) }
    }

    @Published var continuousConversationEnabled: Bool {
        didSet { defaults.set(continuousConversationEnabled, forKey: Keys.continuousConversationEnabled) }
    }

    @Published var spokenRepliesEnabled: Bool {
        didSet { defaults.set(spokenRepliesEnabled, forKey: Keys.spokenRepliesEnabled) }
    }

    @Published var historyEnabled: Bool {
        didSet { defaults.set(historyEnabled, forKey: Keys.historyEnabled) }
    }

    @Published var codexModel: CodexModel {
        didSet { defaults.set(codexModel.rawValue, forKey: Keys.codexModel) }
    }

    @Published var codexEffort: CodexReasoningEffort {
        didSet { defaults.set(codexEffort.rawValue, forKey: Keys.codexEffort) }
    }

    @Published var claudeModel: ClaudeModel {
        didSet { defaults.set(claudeModel.rawValue, forKey: Keys.claudeModel) }
    }

    @Published var claudeEffort: ClaudeReasoningEffort {
        didSet { defaults.set(claudeEffort.rawValue, forKey: Keys.claudeEffort) }
    }

    @Published var avatarStyle: AvatarStyle {
        didSet { defaults.set(avatarStyle.rawValue, forKey: Keys.avatarStyle) }
    }

    @Published var bubblePlacement: BubblePlacement {
        didSet { defaults.set(bubblePlacement.rawValue, forKey: Keys.bubblePlacement) }
    }

    @Published var companionMovementMode: CompanionMovementMode {
        didSet { defaults.set(companionMovementMode.rawValue, forKey: Keys.companionMovementMode) }
    }

    @Published var openAIModel: String {
        didSet { defaults.set(openAIModel, forKey: Keys.openAIModel) }
    }

    @Published var anthropicModel: String {
        didSet { defaults.set(anthropicModel, forKey: Keys.anthropicModel) }
    }

    @Published var geminiModel: String {
        didSet { defaults.set(geminiModel, forKey: Keys.geminiModel) }
    }

    @Published var openRouterModel: String {
        didSet { defaults.set(openRouterModel, forKey: Keys.openRouterModel) }
    }

    @Published var groqModel: String {
        didSet { defaults.set(groqModel, forKey: Keys.groqModel) }
    }

    @Published var ollamaModel: String {
        didSet { defaults.set(ollamaModel, forKey: Keys.ollamaModel) }
    }

    @Published var lmStudioModel: String {
        didSet { defaults.set(lmStudioModel, forKey: Keys.lmStudioModel) }
    }

    @Published var hotKeyShortcut: HotKeyShortcut {
        didSet {
            defaults.set(Int(hotKeyShortcut.keyCode), forKey: Keys.hotKeyKeyCode)
            defaults.set(Int(hotKeyShortcut.modifiers), forKey: Keys.hotKeyModifiers)
        }
    }

    private let defaults = UserDefaults.standard

    init() {
        provider = ProviderSelection(rawValue: defaults.string(forKey: Keys.provider) ?? "") ?? .auto
        voiceLocale = VoiceLocale(rawValue: defaults.string(forKey: Keys.voiceLocale) ?? "") ?? .englishIndia
        speechVoice = SpeechVoicePreset(rawValue: defaults.string(forKey: Keys.speechVoice) ?? "") ?? .warmSamantha
        let storedRate = defaults.double(forKey: Keys.speechRate)
        speechRate = storedRate == 0 ? 0.44 : storedRate
        listenMode = ListenMode(rawValue: defaults.string(forKey: Keys.listenMode) ?? "") ?? .tapToTalk
        codexModel = CodexModel(rawValue: defaults.string(forKey: Keys.codexModel) ?? "") ?? .configured
        codexEffort = CodexReasoningEffort(rawValue: defaults.string(forKey: Keys.codexEffort) ?? "") ?? .xhigh
        claudeModel = ClaudeModel(rawValue: defaults.string(forKey: Keys.claudeModel) ?? "") ?? .sonnet
        claudeEffort = ClaudeReasoningEffort(rawValue: defaults.string(forKey: Keys.claudeEffort) ?? "") ?? .medium
        avatarStyle = AvatarStyle(rawValue: defaults.string(forKey: Keys.avatarStyle) ?? "") ?? .orb
        bubblePlacement = BubblePlacement(rawValue: defaults.string(forKey: Keys.bubblePlacement) ?? "") ?? .above
        companionMovementMode = CompanionMovementMode(rawValue: defaults.string(forKey: Keys.companionMovementMode) ?? "") ?? .stationary
        openAIModel = defaults.string(forKey: Keys.openAIModel) ?? AssistantProvider.openAI.defaultModel
        anthropicModel = defaults.string(forKey: Keys.anthropicModel) ?? AssistantProvider.anthropic.defaultModel
        geminiModel = defaults.string(forKey: Keys.geminiModel) ?? AssistantProvider.gemini.defaultModel
        openRouterModel = defaults.string(forKey: Keys.openRouterModel) ?? AssistantProvider.openRouter.defaultModel
        groqModel = defaults.string(forKey: Keys.groqModel) ?? AssistantProvider.groq.defaultModel
        ollamaModel = defaults.string(forKey: Keys.ollamaModel) ?? AssistantProvider.ollama.defaultModel
        lmStudioModel = defaults.string(forKey: Keys.lmStudioModel) ?? AssistantProvider.lmStudio.defaultModel

        let storedKeyCode = defaults.object(forKey: Keys.hotKeyKeyCode) as? Int
        let storedModifiers = defaults.object(forKey: Keys.hotKeyModifiers) as? Int
        if let storedKeyCode, let storedModifiers {
            hotKeyShortcut = HotKeyShortcut(keyCode: UInt32(storedKeyCode), modifiers: UInt32(storedModifiers))
        } else {
            hotKeyShortcut = .default
        }

        if defaults.object(forKey: Keys.continuousConversationEnabled) == nil {
            continuousConversationEnabled = true
        } else {
            continuousConversationEnabled = defaults.bool(forKey: Keys.continuousConversationEnabled)
        }

        if defaults.object(forKey: Keys.spokenRepliesEnabled) == nil {
            spokenRepliesEnabled = true
        } else {
            spokenRepliesEnabled = defaults.bool(forKey: Keys.spokenRepliesEnabled)
        }

        if defaults.object(forKey: Keys.historyEnabled) == nil {
            historyEnabled = true
        } else {
            historyEnabled = defaults.bool(forKey: Keys.historyEnabled)
        }
    }

    var providerRuntimeOptions: ProviderRuntimeOptions {
        ProviderRuntimeOptions(
            codexModel: codexModel,
            codexEffort: codexEffort,
            claudeModel: claudeModel,
            claudeEffort: claudeEffort,
            providerModels: [
                .codex: codexModel.title,
                .claude: claudeModel.title,
                .cursor: AssistantProvider.cursor.defaultModel,
                .opencode: AssistantProvider.opencode.defaultModel,
                .antigravity: AssistantProvider.antigravity.defaultModel,
                .appleIntelligence: AssistantProvider.appleIntelligence.defaultModel,
                .ollama: ollamaModel,
                .lmStudio: lmStudioModel,
                .openAI: openAIModel,
                .anthropic: anthropicModel,
                .gemini: geminiModel,
                .openRouter: openRouterModel,
                .groq: groqModel
            ]
        )
    }

    func resetToDefaults() {
        provider = .auto
        voiceLocale = .englishIndia
        speechVoice = .warmSamantha
        speechRate = 0.44
        listenMode = .tapToTalk
        continuousConversationEnabled = true
        spokenRepliesEnabled = true
        historyEnabled = true
        codexModel = .configured
        codexEffort = .xhigh
        claudeModel = .sonnet
        claudeEffort = .medium
        avatarStyle = .orb
        bubblePlacement = .above
        companionMovementMode = .stationary
        openAIModel = AssistantProvider.openAI.defaultModel
        anthropicModel = AssistantProvider.anthropic.defaultModel
        geminiModel = AssistantProvider.gemini.defaultModel
        openRouterModel = AssistantProvider.openRouter.defaultModel
        groqModel = AssistantProvider.groq.defaultModel
        ollamaModel = AssistantProvider.ollama.defaultModel
        lmStudioModel = AssistantProvider.lmStudio.defaultModel
        hotKeyShortcut = .default
    }

    private enum Keys {
        static let provider = "provider"
        static let voiceLocale = "voiceLocale"
        static let speechVoice = "speechVoice"
        static let speechRate = "speechRate"
        static let listenMode = "listenMode"
        static let continuousConversationEnabled = "continuousConversationEnabled"
        static let spokenRepliesEnabled = "spokenRepliesEnabled"
        static let historyEnabled = "historyEnabled"
        static let codexModel = "codexModel"
        static let codexEffort = "codexEffort"
        static let claudeModel = "claudeModel"
        static let claudeEffort = "claudeEffort"
        static let avatarStyle = "avatarStyle"
        static let bubblePlacement = "bubblePlacement"
        static let companionMovementMode = "companionMovementMode"
        static let openAIModel = "openAIModel"
        static let anthropicModel = "anthropicModel"
        static let geminiModel = "geminiModel"
        static let openRouterModel = "openRouterModel"
        static let groqModel = "groqModel"
        static let ollamaModel = "ollamaModel"
        static let lmStudioModel = "lmStudioModel"
        static let hotKeyKeyCode = "hotKeyKeyCode"
        static let hotKeyModifiers = "hotKeyModifiers"
    }
}
