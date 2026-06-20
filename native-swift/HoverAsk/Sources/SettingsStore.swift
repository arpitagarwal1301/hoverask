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
            claudeEffort: claudeEffort
        )
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
    }
}
