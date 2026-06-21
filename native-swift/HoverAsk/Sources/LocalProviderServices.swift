import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum SupportConfig {
    static let supportURL = URL(string: "https://github.com/sponsors/arpitagarwal1301")
}

enum AppleIntelligenceService {
    static func availability() -> AppleIntelligenceAvailability {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            return AppleFoundationModelsAdapter.availability()
        }
        return .unavailable("Requires macOS 26 or newer")
        #else
        return .unavailable("Foundation Models unavailable")
        #endif
    }

    static func answer(prompt: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            return try await AppleFoundationModelsAdapter.answer(prompt: prompt)
        }
        throw ProviderBackendError.requestFailed("Apple Intelligence requires macOS 26 or newer.")
        #else
        throw ProviderBackendError.requestFailed("Foundation Models is not available in this build.")
        #endif
    }
}

#if canImport(FoundationModels)
@available(macOS 26.0, *)
private enum AppleFoundationModelsAdapter {
    static func availability() -> AppleIntelligenceAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available("Available on this Mac")
        case .unavailable(let reason):
            return .unavailable(message(for: reason))
        }
    }

    static func answer(prompt: String) async throws -> String {
        let availability = availability()
        guard availability.isAvailable else {
            throw ProviderBackendError.requestFailed(availability.title)
        }

        let instructions = [
            "You are HoverAsk, a concise floating macOS voice assistant.",
            "Answer conversationally and directly.",
            "Keep replies useful when spoken aloud.",
            "Reply in the same language style as the user. If the user mixes Hindi and English, reply naturally in Hinglish.",
            "Do not claim screen awareness, screenshots, or private app context."
        ].joined(separator: "\n")
        let session = LanguageModelSession(model: .default, instructions: instructions)
        let response = try await session.respond(to: prompt)
        let answer = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else {
            throw ProviderBackendError.invalidResponse("Apple Intelligence returned no text.")
        }
        return answer
    }

    private static func message(for reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "This Mac is not eligible for Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is not enabled in System Settings."
        case .modelNotReady:
            return "Apple Intelligence model is not ready yet."
        @unknown default:
            return "Apple Intelligence is not available on this Mac."
        }
    }
}
#endif

enum LocalProviderService {
    static func health() -> [LocalProviderHealth] {
        let appleAvailability = AppleIntelligenceService.availability()
        let appleStatus: LocalProviderStatus = appleAvailability.isAvailable
            ? .available(appleAvailability.title)
            : .unavailable(appleAvailability.title)

        return [
            LocalProviderHealth(kind: .appleIntelligence, status: appleStatus, model: "Apple Default"),
            LocalProviderHealth(kind: .ollama, status: .unavailable("Planned"), model: "Qwen3:14B"),
            LocalProviderHealth(kind: .lmStudio, status: .unavailable("Planned"), model: "Phi-3.5 Mini")
        ]
    }
}
