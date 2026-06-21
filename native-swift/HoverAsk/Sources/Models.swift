import Carbon
import Foundation

enum ProviderSelection: String, CaseIterable, Codable, Identifiable {
    case auto
    case codex
    case claude
    case cursor
    case opencode
    case antigravity
    case appleIntelligence
    case ollama
    case lmStudio
    case openAI
    case anthropic
    case gemini
    case openRouter
    case groq

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: "Auto"
        case .codex: "Codex"
        case .claude: "Claude"
        case .cursor: "Cursor"
        case .opencode: "OpenCode"
        case .antigravity: "Antigravity"
        case .appleIntelligence: "Apple Intelligence"
        case .ollama: "Ollama"
        case .lmStudio: "LM Studio"
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .gemini: "Gemini"
        case .openRouter: "OpenRouter"
        case .groq: "Groq"
        }
    }

    var provider: AssistantProvider? {
        switch self {
        case .auto:
            return nil
        case .codex:
            return .codex
        case .claude:
            return .claude
        case .cursor:
            return .cursor
        case .opencode:
            return .opencode
        case .antigravity:
            return .antigravity
        case .appleIntelligence:
            return .appleIntelligence
        case .ollama:
            return .ollama
        case .lmStudio:
            return .lmStudio
        case .openAI:
            return .openAI
        case .anthropic:
            return .anthropic
        case .gemini:
            return .gemini
        case .openRouter:
            return .openRouter
        case .groq:
            return .groq
        }
    }
}

enum AssistantProvider: String, CaseIterable, Codable, Identifiable {
    case codex
    case claude
    case cursor
    case opencode
    case antigravity
    case appleIntelligence
    case ollama
    case lmStudio
    case openAI
    case anthropic
    case gemini
    case openRouter
    case groq

    var id: String { rawValue }

    var title: String {
        switch self {
        case .codex: "Codex"
        case .claude: "Claude"
        case .cursor: "Cursor"
        case .opencode: "OpenCode"
        case .antigravity: "Antigravity"
        case .appleIntelligence: "Apple Intelligence"
        case .ollama: "Ollama"
        case .lmStudio: "LM Studio"
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .gemini: "Gemini"
        case .openRouter: "OpenRouter"
        case .groq: "Groq"
        }
    }

    var category: ProviderCategory {
        switch self {
        case .codex, .claude, .cursor, .opencode, .antigravity:
            return .cli
        case .appleIntelligence, .ollama, .lmStudio:
            return .local
        case .openAI, .anthropic, .gemini, .openRouter, .groq:
            return .byok
        }
    }

    var selection: ProviderSelection {
        switch self {
        case .codex: .codex
        case .claude: .claude
        case .cursor: .cursor
        case .opencode: .opencode
        case .antigravity: .antigravity
        case .appleIntelligence: .appleIntelligence
        case .ollama: .ollama
        case .lmStudio: .lmStudio
        case .openAI: .openAI
        case .anthropic: .anthropic
        case .gemini: .gemini
        case .openRouter: .openRouter
        case .groq: .groq
        }
    }

    var supportsEffort: Bool {
        self == .codex || self == .claude
    }

    var supportsLogin: Bool {
        category == .cli
    }

    var defaultModel: String {
        switch self {
        case .codex: "Codex default"
        case .claude: "Sonnet"
        case .cursor, .opencode, .antigravity: "CLI default"
        case .appleIntelligence: "Apple Default"
        case .ollama: "llama3.2"
        case .lmStudio: "local-model"
        case .openAI: "gpt-4.1-mini"
        case .anthropic: "claude-sonnet-4-20250514"
        case .gemini: "gemini-2.5-flash"
        case .openRouter: "openai/gpt-4.1-mini"
        case .groq: "llama-3.3-70b-versatile"
        }
    }

    static let cliProviders: [AssistantProvider] = [.codex, .claude, .cursor, .opencode, .antigravity]
    static let localProviders: [AssistantProvider] = [.appleIntelligence, .ollama, .lmStudio]
    static let byokProviders: [AssistantProvider] = [.openAI, .anthropic, .gemini, .openRouter, .groq]
    static let defaultRouteOrder: [AssistantProvider] = cliProviders + localProviders + byokProviders
}

enum ProviderCategory: String, Codable, Identifiable {
    case cli
    case local
    case byok

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cli: "Account CLI"
        case .local: "Private Local"
        case .byok: "BYOK Cloud"
        }
    }

    var shortTitle: String {
        switch self {
        case .cli: "CLI"
        case .local: "Local"
        case .byok: "BYOK"
        }
    }
}

enum VoiceLocale: String, CaseIterable, Codable, Identifiable {
    case englishIndia = "en-IN"
    case hindiIndia = "hi-IN"
    case englishUS = "en-US"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .englishIndia: "English / Hinglish"
        case .hindiIndia: "Hindi"
        case .englishUS: "English US"
        }
    }
}

enum SpeechVoicePreset: String, CaseIterable, Codable, Identifiable {
    case warmSamantha
    case indianRishi
    case britishDaniel
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .warmSamantha: "Warm English"
        case .indianRishi: "Indian English"
        case .britishDaniel: "British English"
        case .system: "System Default"
        }
    }

    var voiceIdentifier: String? {
        switch self {
        case .warmSamantha: "com.apple.voice.compact.en-US.Samantha"
        case .indianRishi: "com.apple.voice.compact.en-IN.Rishi"
        case .britishDaniel: "com.apple.voice.super-compact.en-GB.Daniel"
        case .system: nil
        }
    }
}

enum ListenMode: String, CaseIterable, Codable, Identifiable {
    case tapToTalk
    case holdToTalk
    case manualStop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tapToTalk: "Tap to talk"
        case .holdToTalk: "Hold to talk"
        case .manualStop: "Manual stop"
        }
    }
}

enum CodexModel: String, CaseIterable, Codable, Identifiable {
    case configured
    case gpt55 = "gpt-5.5"
    case gpt54 = "gpt-5.4"
    case gpt54Mini = "gpt-5.4-mini"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .configured: "Codex default"
        case .gpt55: "GPT-5.5"
        case .gpt54: "GPT-5.4"
        case .gpt54Mini: "GPT-5.4 Mini"
        }
    }

    var cliValue: String? {
        switch self {
        case .configured: nil
        case .gpt55, .gpt54, .gpt54Mini: rawValue
        }
    }
}

enum CodexReasoningEffort: String, CaseIterable, Codable, Identifiable {
    case low
    case medium
    case high
    case xhigh

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .xhigh: "XHigh"
        }
    }
}

enum ClaudeModel: String, CaseIterable, Codable, Identifiable {
    case sonnet
    case opus
    case fable
    case configured

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sonnet: "Sonnet"
        case .opus: "Opus"
        case .fable: "Fable"
        case .configured: "Claude default"
        }
    }

    var cliValue: String? {
        switch self {
        case .configured: nil
        case .sonnet, .opus, .fable: rawValue
        }
    }
}

enum ClaudeReasoningEffort: String, CaseIterable, Codable, Identifiable {
    case low
    case medium
    case high
    case xhigh
    case max

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .xhigh: "XHigh"
        case .max: "Max"
        }
    }
}

enum ProviderEffort: String, CaseIterable, Codable, Identifiable {
    case `default`
    case low
    case medium
    case high
    case xhigh
    case max

    var id: String { rawValue }

    var title: String {
        switch self {
        case .default: "Default"
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .xhigh: "XHigh"
        case .max: "Max"
        }
    }

    init(codex effort: CodexReasoningEffort) {
        switch effort {
        case .low: self = .low
        case .medium: self = .medium
        case .high: self = .high
        case .xhigh: self = .xhigh
        }
    }

    init(claude effort: ClaudeReasoningEffort) {
        switch effort {
        case .low: self = .low
        case .medium: self = .medium
        case .high: self = .high
        case .xhigh: self = .xhigh
        case .max: self = .max
        }
    }
}

struct ProviderModelChoice: Codable, Hashable, Identifiable {
    var provider: AssistantProvider
    var modelID: String
    var effort: ProviderEffort
    var displayTitle: String

    var id: String { "\(provider.rawValue):\(modelID):\(effort.rawValue)" }

    var isModelSelected: Bool {
        !modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func defaultChoice(for provider: AssistantProvider) -> ProviderModelChoice {
        ProviderModelChoice(
            provider: provider,
            modelID: provider.defaultModel,
            effort: provider.supportsEffort ? .medium : .default,
            displayTitle: provider.defaultModel
        )
    }
}

enum ProviderReadinessState: Equatable {
    case missing
    case needsLogin
    case keyRequired
    case modelRequired
    case ready
    case disabled
    case failed(String)

    var title: String {
        switch self {
        case .missing: "Missing"
        case .needsLogin: "Needs login"
        case .keyRequired: "Not connected"
        case .modelRequired: "Model required"
        case .ready: "Ready"
        case .disabled: "Disabled"
        case .failed: "Failed"
        }
    }

    var isReady: Bool {
        if case .ready = self {
            return true
        }
        return false
    }
}

enum VoiceTestState: Equatable {
    case idle
    case testing(String)
    case microphoneLevel(Double)
    case passed(String)
    case failed(String)

    var title: String {
        switch self {
        case .idle: "Ready"
        case .testing(let text): text
        case .microphoneLevel: "Listening"
        case .passed(let text): text
        case .failed(let text): text
        }
    }
}

enum AvatarStyle: String, CaseIterable, Codable, Identifiable {
    case orb
    case dog
    case cat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .orb: "Glass Orb"
        case .dog: "Glass Dog"
        case .cat: "Glass Cat"
        }
    }

    var isCompanion: Bool {
        self == .dog || self == .cat
    }
}

enum CompanionMovementMode: String, CaseIterable, Codable, Identifiable {
    case stationary
    case roam
    case chaseCursor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stationary: "Stationary"
        case .roam: "Roam"
        case .chaseCursor: "Chase cursor"
        }
    }
}

enum SettingsSection: String, CaseIterable, Identifiable {
    case overview
    case assistant
    case voice
    case appearance
    case providers
    case chatHistory
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .assistant: "AI Assistant"
        case .voice: "Voice"
        case .appearance: "Avatar"
        case .providers: "Providers"
        case .chatHistory: "Chat History"
        case .advanced: "Advanced"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: "house"
        case .assistant: "sparkles"
        case .voice: "mic"
        case .appearance: "paintbrush"
        case .providers: "powerplug"
        case .chatHistory: "clock.arrow.circlepath"
        case .advanced: "slider.horizontal.3"
        }
    }
}

enum LocalProviderKind: String, CaseIterable, Identifiable {
    case appleIntelligence
    case ollama
    case lmStudio

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appleIntelligence: "Apple Intelligence"
        case .ollama: "Ollama"
        case .lmStudio: "LM Studio"
        }
    }

    var detail: String {
        switch self {
        case .appleIntelligence: "On-device"
        case .ollama: "localhost:11434"
        case .lmStudio: "localhost:1234"
        }
    }
}

enum LocalProviderStatus: Equatable {
    case available(String)
    case unavailable(String)
    case notRunning(String)
    case running(String)

    var title: String {
        switch self {
        case .available(let text), .unavailable(let text), .notRunning(let text), .running(let text):
            text
        }
    }

    var isPositive: Bool {
        switch self {
        case .available, .running:
            return true
        case .unavailable, .notRunning:
            return false
        }
    }
}

struct LocalProviderHealth: Identifiable, Equatable {
    let kind: LocalProviderKind
    let status: LocalProviderStatus
    let model: String

    var id: LocalProviderKind { kind }
}

enum AppleIntelligenceAvailability: Equatable {
    case available(String)
    case unavailable(String)

    var title: String {
        switch self {
        case .available(let text), .unavailable(let text):
            text
        }
    }

    var isAvailable: Bool {
        switch self {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }
}

struct CompanionVisualMotion: Equatable {
    let isRunning: Bool
    let facingRight: Bool

    static let idle = CompanionVisualMotion(isRunning: false, facingRight: false)
}

enum BubblePlacement: String, CaseIterable, Codable, Identifiable {
    case above
    case side
    case bottom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .above: "Above"
        case .side: "Side"
        case .bottom: "Bottom"
        }
    }
}

struct ProviderRuntimeOptions {
    let codexModel: CodexModel
    let codexEffort: CodexReasoningEffort
    let claudeModel: ClaudeModel
    let claudeEffort: ClaudeReasoningEffort
    let providerModels: [AssistantProvider: String]
    var disabledProviders: Set<AssistantProvider> = []
    var providerRouteOrder: [AssistantProvider] = AssistantProvider.defaultRouteOrder
    var providerModelChoices: [AssistantProvider: ProviderModelChoice] = [:]

    func model(for provider: AssistantProvider) -> String {
        let model = providerModelChoices[provider]?.modelID.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? providerModels[provider]?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""
        return model.isEmpty ? provider.defaultModel : model
    }
}

enum OrbPhase: Equatable {
    case idle
    case chat
    case listening
    case thinking
    case answer
    case error(String)
    case settings
}

struct ProviderHealth: Identifiable, Equatable {
    let provider: AssistantProvider
    let installed: Bool
    let authenticated: Bool
    let detail: String

    var id: AssistantProvider { provider }
}

struct HistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let provider: AssistantProvider
    let prompt: String
    let answer: String
}

enum SessionExchangeStatus: Equatable {
    case pending
    case answered
    case failed(String)
}

struct SessionExchange: Identifiable, Equatable {
    let id: UUID
    let question: String
    var answer: String
    var provider: AssistantProvider?
    var status: SessionExchangeStatus
}

struct AssistantResult {
    let provider: AssistantProvider
    let text: String
    let duration: TimeInterval
}

struct ProviderTestResult: Equatable {
    let provider: AssistantProvider
    let success: Bool
    let message: String
    let duration: TimeInterval?
}

struct HotKeyShortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let `default` = HotKeyShortcut(keyCode: 49, modifiers: UInt32(cmdKey | shiftKey))

    var displayText: String {
        var parts: [String] = []
        if modifiers & UInt32(cmdKey) != 0 { parts.append("Cmd") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("Shift") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("Option") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("Control") }
        parts.append(Self.keyName(for: keyCode))
        return parts.joined(separator: " + ")
    }

    static func keyName(for keyCode: UInt32) -> String {
        switch keyCode {
        case 49: "Space"
        case 36: "Return"
        case 53: "Esc"
        case 48: "Tab"
        default: "Key \(keyCode)"
        }
    }
}
