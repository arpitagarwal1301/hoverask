import Foundation

enum ProviderSelection: String, CaseIterable, Codable, Identifiable {
    case auto
    case codex
    case claude
    case cursor
    case opencode
    case antigravity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: "Auto"
        case .codex: "Codex"
        case .claude: "Claude"
        case .cursor: "Cursor"
        case .opencode: "OpenCode"
        case .antigravity: "Antigravity"
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
        }
    }
}

enum AssistantProvider: String, CaseIterable, Codable, Identifiable {
    case codex
    case claude
    case cursor
    case opencode
    case antigravity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .codex: "Codex"
        case .claude: "Claude"
        case .cursor: "Cursor"
        case .opencode: "OpenCode"
        case .antigravity: "Antigravity"
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
