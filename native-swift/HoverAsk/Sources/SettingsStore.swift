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

    @Published var disabledProviders: Set<AssistantProvider> {
        didSet { saveDisabledProviders() }
    }

    @Published var providerRouteOrder: [AssistantProvider] {
        didSet { saveProviderRouteOrder() }
    }

    @Published var providerModelChoices: [AssistantProvider: ProviderModelChoice] {
        didSet { saveProviderModelChoices() }
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
        disabledProviders = Self.loadProviderSet(defaults: defaults, key: Keys.disabledProviders)
        providerRouteOrder = Self.loadProviderArray(defaults: defaults, key: Keys.providerRouteOrder)
        providerModelChoices = Self.loadModelChoices(defaults: defaults, key: Keys.providerModelChoices)

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

        seedMissingModelChoices()
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
            ],
            disabledProviders: disabledProviders,
            providerRouteOrder: normalizedRouteOrder,
            providerModelChoices: providerModelChoices
        )
    }

    var normalizedRouteOrder: [AssistantProvider] {
        let unique = providerRouteOrder.reduce(into: [AssistantProvider]()) { result, provider in
            if !result.contains(provider) {
                result.append(provider)
            }
        }
        return unique.isEmpty ? AssistantProvider.defaultRouteOrder : unique
    }

    func providerModelChoice(for provider: AssistantProvider) -> ProviderModelChoice {
        providerModelChoices[provider] ?? legacyModelChoice(for: provider)
    }

    func setProviderModelChoice(_ choice: ProviderModelChoice, for provider: AssistantProvider) {
        providerModelChoices[provider] = choice
        applyChoiceToLegacyFields(choice)
    }

    func setProviderModelID(_ modelID: String, for provider: AssistantProvider) {
        var choice = providerModelChoice(for: provider)
        choice.modelID = modelID
        choice.displayTitle = modelID
        setProviderModelChoice(choice, for: provider)
    }

    func setProviderDisabled(_ disabled: Bool, provider: AssistantProvider) {
        if disabled {
            disabledProviders.insert(provider)
        } else {
            disabledProviders.remove(provider)
        }
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
        disabledProviders = []
        providerRouteOrder = AssistantProvider.defaultRouteOrder
        providerModelChoices = [:]
        seedMissingModelChoices()
        hotKeyShortcut = .default
    }

    private func seedMissingModelChoices() {
        var choices = providerModelChoices
        for provider in AssistantProvider.allCases where choices[provider] == nil {
            choices[provider] = legacyModelChoice(for: provider)
        }
        providerModelChoices = choices
    }

    private func legacyModelChoice(for provider: AssistantProvider) -> ProviderModelChoice {
        let model: String
        let effort: ProviderEffort
        switch provider {
        case .codex:
            model = codexModel.title
            effort = ProviderEffort(codex: codexEffort)
        case .claude:
            model = claudeModel.title
            effort = ProviderEffort(claude: claudeEffort)
        case .ollama:
            model = ollamaModel
            effort = .default
        case .lmStudio:
            model = lmStudioModel
            effort = .default
        case .openAI:
            model = openAIModel
            effort = .medium
        case .anthropic:
            model = anthropicModel
            effort = .default
        case .gemini:
            model = geminiModel
            effort = .default
        case .openRouter:
            model = openRouterModel
            effort = .default
        case .groq:
            model = groqModel
            effort = .default
        case .cursor, .opencode, .antigravity, .appleIntelligence:
            model = provider.defaultModel
            effort = .default
        }
        return ProviderModelChoice(provider: provider, modelID: model, effort: effort, displayTitle: model)
    }

    private func applyChoiceToLegacyFields(_ choice: ProviderModelChoice) {
        switch choice.provider {
        case .codex:
            if let model = CodexModel.allCases.first(where: { $0.title == choice.modelID || $0.rawValue == choice.modelID }) {
                codexModel = model
            }
            switch choice.effort {
            case .low: codexEffort = .low
            case .medium, .default: codexEffort = .medium
            case .high: codexEffort = .high
            case .xhigh, .max: codexEffort = .xhigh
            }
        case .claude:
            if let model = ClaudeModel.allCases.first(where: { $0.title == choice.modelID || $0.rawValue == choice.modelID }) {
                claudeModel = model
            }
            switch choice.effort {
            case .low: claudeEffort = .low
            case .medium, .default: claudeEffort = .medium
            case .high: claudeEffort = .high
            case .xhigh: claudeEffort = .xhigh
            case .max: claudeEffort = .max
            }
        case .ollama:
            ollamaModel = choice.modelID
        case .lmStudio:
            lmStudioModel = choice.modelID
        case .openAI:
            openAIModel = choice.modelID
        case .anthropic:
            anthropicModel = choice.modelID
        case .gemini:
            geminiModel = choice.modelID
        case .openRouter:
            openRouterModel = choice.modelID
        case .groq:
            groqModel = choice.modelID
        case .cursor, .opencode, .antigravity, .appleIntelligence:
            break
        }
    }

    private func saveDisabledProviders() {
        defaults.set(disabledProviders.map(\.rawValue), forKey: Keys.disabledProviders)
    }

    private func saveProviderRouteOrder() {
        defaults.set(providerRouteOrder.map(\.rawValue), forKey: Keys.providerRouteOrder)
    }

    private func saveProviderModelChoices() {
        let payload = Dictionary(uniqueKeysWithValues: providerModelChoices.map { ($0.key.rawValue, $0.value) })
        guard let data = try? JSONEncoder().encode(payload) else {
            return
        }
        defaults.set(data, forKey: Keys.providerModelChoices)
    }

    private static func loadProviderSet(defaults: UserDefaults, key: String) -> Set<AssistantProvider> {
        let rawValues = defaults.stringArray(forKey: key) ?? []
        return Set(rawValues.compactMap(AssistantProvider.init(rawValue:)))
    }

    private static func loadProviderArray(defaults: UserDefaults, key: String) -> [AssistantProvider] {
        let rawValues = defaults.stringArray(forKey: key) ?? []
        let providers = rawValues.compactMap(AssistantProvider.init(rawValue:))
        return providers.isEmpty ? AssistantProvider.defaultRouteOrder : providers
    }

    private static func loadModelChoices(defaults: UserDefaults, key: String) -> [AssistantProvider: ProviderModelChoice] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: ProviderModelChoice].self, from: data)
        else {
            return [:]
        }
        return decoded.reduce(into: [AssistantProvider: ProviderModelChoice]()) { result, pair in
            guard let provider = AssistantProvider(rawValue: pair.key) else {
                return
            }
            result[provider] = pair.value
        }
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
        static let disabledProviders = "disabledProviders"
        static let providerRouteOrder = "providerRouteOrder"
        static let providerModelChoices = "providerModelChoices"
        static let hotKeyKeyCode = "hotKeyKeyCode"
        static let hotKeyModifiers = "hotKeyModifiers"
    }
}
