import Foundation
import Security

enum ProviderBackendError: LocalizedError {
    case missingKey(AssistantProvider)
    case unsupported(AssistantProvider)
    case invalidResponse(String)
    case requestFailed(String)
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .missingKey(let provider):
            return "\(provider.title) API key is not connected."
        case .unsupported(let provider):
            return "\(provider.title) is not supported in this build."
        case .invalidResponse(let message):
            return message
        case .requestFailed(let message):
            return message
        case .keychain(let status):
            return "Keychain error \(status)."
        }
    }
}

enum BYOKKeychain {
    static let service = "app.hoverask.byok"

    static func save(_ key: String, for provider: AssistantProvider) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ProviderBackendError.requestFailed("API key cannot be empty.")
        }
        let data = Data(trimmed.utf8)
        let query = baseQuery(provider)
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw ProviderBackendError.keychain(status)
        }
    }

    static func read(for provider: AssistantProvider) throws -> String? {
        var query = baseQuery(provider)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw ProviderBackendError.keychain(status)
        }
        guard let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    static func hasKey(for provider: AssistantProvider) -> Bool {
        guard let key = try? read(for: provider) else {
            return false
        }
        return !key.isEmpty
    }

    static func delete(for provider: AssistantProvider) throws {
        let status = SecItemDelete(baseQuery(provider) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw ProviderBackendError.keychain(status)
        }
    }

    private static func baseQuery(_ provider: AssistantProvider) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue
        ]
    }
}

struct BYOKClient {
    func ask(provider: AssistantProvider, prompt: String, model: String) async throws -> String {
        guard let key = try BYOKKeychain.read(for: provider) else {
            throw ProviderBackendError.missingKey(provider)
        }

        switch provider {
        case .openAI:
            return try await openAI(prompt: prompt, model: model, key: key)
        case .anthropic:
            return try await anthropic(prompt: prompt, model: model, key: key)
        case .gemini:
            return try await gemini(prompt: prompt, model: model, key: key)
        case .openRouter:
            return try await chatCompletions(
                url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!,
                prompt: prompt,
                model: model,
                key: key,
                extraHeaders: [
                    "HTTP-Referer": "https://github.com/arpitagarwal1301/hoverask",
                    "X-Title": "HoverAsk"
                ]
            )
        case .groq:
            return try await chatCompletions(
                url: URL(string: "https://api.groq.com/openai/v1/chat/completions")!,
                prompt: prompt,
                model: model,
                key: key,
                extraHeaders: [:]
            )
        default:
            throw ProviderBackendError.unsupported(provider)
        }
    }

    func fetchModels(provider: AssistantProvider) async throws -> [String] {
        guard let key = try BYOKKeychain.read(for: provider) else {
            throw ProviderBackendError.missingKey(provider)
        }

        switch provider {
        case .openAI:
            return try await modelList(url: URL(string: "https://api.openai.com/v1/models")!, key: key)
        case .anthropic:
            return try await modelList(url: URL(string: "https://api.anthropic.com/v1/models")!, key: key, extraHeaders: ["anthropic-version": "2023-06-01"])
        case .gemini:
            let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(urlEncoded(key))")!
            let object = try await jsonObject(url: url, method: "GET", headers: [:], body: nil)
            let models = (object["models"] as? [[String: Any]]) ?? []
            return models.compactMap { model in
                (model["name"] as? String)?.replacingOccurrences(of: "models/", with: "")
            }.sorted()
        case .openRouter:
            return try await modelList(url: URL(string: "https://openrouter.ai/api/v1/models")!, key: key)
        case .groq:
            return try await modelList(url: URL(string: "https://api.groq.com/openai/v1/models")!, key: key)
        default:
            throw ProviderBackendError.unsupported(provider)
        }
    }

    private func openAI(prompt: String, model: String, key: String) async throws -> String {
        let body: [String: Any] = [
            "model": model,
            "input": prompt,
            "max_output_tokens": 800
        ]
        let object = try await jsonObject(
            url: URL(string: "https://api.openai.com/v1/responses")!,
            method: "POST",
            headers: ["Authorization": "Bearer \(key)"],
            body: body
        )
        if let output = object["output_text"] as? String, !output.isEmpty {
            return output
        }
        if let output = object["output"] as? [[String: Any]] {
            let text = output
                .flatMap { ($0["content"] as? [[String: Any]]) ?? [] }
                .compactMap { $0["text"] as? String }
                .joined(separator: "\n")
            if !text.isEmpty {
                return text
            }
        }
        throw ProviderBackendError.invalidResponse("OpenAI returned no text.")
    }

    private func anthropic(prompt: String, model: String, key: String) async throws -> String {
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 800,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        let object = try await jsonObject(
            url: URL(string: "https://api.anthropic.com/v1/messages")!,
            method: "POST",
            headers: [
                "x-api-key": key,
                "anthropic-version": "2023-06-01"
            ],
            body: body
        )
        let text = ((object["content"] as? [[String: Any]]) ?? [])
            .compactMap { $0["text"] as? String }
            .joined(separator: "\n")
        guard !text.isEmpty else {
            throw ProviderBackendError.invalidResponse("Anthropic returned no text.")
        }
        return text
    }

    private func gemini(prompt: String, model: String, key: String) async throws -> String {
        let encodedKey = urlEncoded(key)
        let encodedModel = urlEncoded(model)
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        let object = try await jsonObject(
            url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(encodedModel):generateContent?key=\(encodedKey)")!,
            method: "POST",
            headers: [:],
            body: body
        )
        let text = ((object["candidates"] as? [[String: Any]]) ?? [])
            .compactMap { $0["content"] as? [String: Any] }
            .flatMap { ($0["parts"] as? [[String: Any]]) ?? [] }
            .compactMap { $0["text"] as? String }
            .joined(separator: "\n")
        guard !text.isEmpty else {
            throw ProviderBackendError.invalidResponse("Gemini returned no text.")
        }
        return text
    }

    private func chatCompletions(url: URL, prompt: String, model: String, key: String, extraHeaders: [String: String]) async throws -> String {
        var headers = ["Authorization": "Bearer \(key)"]
        extraHeaders.forEach { headers[$0.key] = $0.value }
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 800
        ]
        let object = try await jsonObject(url: url, method: "POST", headers: headers, body: body)
        let text = ((object["choices"] as? [[String: Any]]) ?? [])
            .compactMap { $0["message"] as? [String: Any] }
            .compactMap { $0["content"] as? String }
            .joined(separator: "\n")
        guard !text.isEmpty else {
            throw ProviderBackendError.invalidResponse("Provider returned no text.")
        }
        return text
    }

    private func modelList(url: URL, key: String, extraHeaders: [String: String] = [:]) async throws -> [String] {
        var headers = ["Authorization": "Bearer \(key)"]
        extraHeaders.forEach { headers[$0.key] = $0.value }
        let object = try await jsonObject(url: url, method: "GET", headers: headers, body: nil)
        let models = (object["data"] as? [[String: Any]]) ?? []
        return models.compactMap { $0["id"] as? String }.sorted()
    }

    private func jsonObject(url: URL, method: String, headers: [String: String], body: [String: Any]?) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        guard (200..<300).contains(status), let object else {
            let message = ((object?["error"] as? [String: Any])?["message"] as? String)
                ?? (object?["message"] as? String)
                ?? String(data: data, encoding: .utf8)
                ?? "HTTP \(status)"
            throw ProviderBackendError.requestFailed(message)
        }
        return object
    }

    private func urlEncoded(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }
}

struct LocalModelClient {
    func health(provider: AssistantProvider, model: String) async -> ProviderHealth {
        switch provider {
        case .appleIntelligence:
            let availability = AppleIntelligenceService.availability()
            return ProviderHealth(provider: provider, installed: true, authenticated: availability.isAvailable, detail: availability.title)
        case .ollama:
            do {
                let models = try await ollamaModels()
                let detail = models.isEmpty ? "Ollama is reachable, no models found." : "Models: \(models.prefix(5).joined(separator: ", "))"
                return ProviderHealth(provider: provider, installed: true, authenticated: !models.isEmpty, detail: detail)
            } catch {
                return ProviderHealth(provider: provider, installed: true, authenticated: false, detail: error.localizedDescription)
            }
        case .lmStudio:
            do {
                let models = try await lmStudioModels()
                let detail = models.isEmpty ? "LM Studio server is reachable, no models found." : "Models: \(models.prefix(5).joined(separator: ", "))"
                return ProviderHealth(provider: provider, installed: true, authenticated: !models.isEmpty, detail: detail)
            } catch {
                return ProviderHealth(provider: provider, installed: true, authenticated: false, detail: error.localizedDescription)
            }
        default:
            return ProviderHealth(provider: provider, installed: false, authenticated: false, detail: "Not a local provider.")
        }
    }

    func ask(provider: AssistantProvider, prompt: String, model: String) async throws -> String {
        switch provider {
        case .appleIntelligence:
            let availability = AppleIntelligenceService.availability()
            guard availability.isAvailable else {
                throw ProviderBackendError.requestFailed(availability.title)
            }
            return try await AppleIntelligenceService.answer(prompt: prompt)
        case .ollama:
            return try await ollama(prompt: prompt, model: model)
        case .lmStudio:
            return try await lmStudio(prompt: prompt, model: model)
        default:
            throw ProviderBackendError.unsupported(provider)
        }
    }

    func fetchModels(provider: AssistantProvider) async throws -> [String] {
        switch provider {
        case .ollama:
            return try await ollamaModels()
        case .lmStudio:
            return try await lmStudioModels()
        case .appleIntelligence:
            return ["Apple Default"]
        default:
            throw ProviderBackendError.unsupported(provider)
        }
    }

    private func ollamaModels() async throws -> [String] {
        let object = try await jsonObject(url: URL(string: "http://127.0.0.1:11434/api/tags")!, method: "GET", body: nil)
        let models = (object["models"] as? [[String: Any]]) ?? []
        return models.compactMap { $0["name"] as? String }.sorted()
    }

    private func ollama(prompt: String, model: String) async throws -> String {
        let object = try await jsonObject(
            url: URL(string: "http://127.0.0.1:11434/api/generate")!,
            method: "POST",
            body: ["model": model, "prompt": prompt, "stream": false]
        )
        guard let response = object["response"] as? String, !response.isEmpty else {
            throw ProviderBackendError.invalidResponse("Ollama returned no text.")
        }
        return response
    }

    private func lmStudioModels() async throws -> [String] {
        let object = try await jsonObject(url: URL(string: "http://127.0.0.1:1234/v1/models")!, method: "GET", body: nil)
        let models = (object["data"] as? [[String: Any]]) ?? []
        return models.compactMap { $0["id"] as? String }.sorted()
    }

    private func lmStudio(prompt: String, model: String) async throws -> String {
        let object = try await jsonObject(
            url: URL(string: "http://127.0.0.1:1234/v1/chat/completions")!,
            method: "POST",
            body: [
                "model": model,
                "messages": [["role": "user", "content": prompt]],
                "max_tokens": 800
            ]
        )
        let text = ((object["choices"] as? [[String: Any]]) ?? [])
            .compactMap { $0["message"] as? [String: Any] }
            .compactMap { $0["content"] as? String }
            .joined(separator: "\n")
        guard !text.isEmpty else {
            throw ProviderBackendError.invalidResponse("LM Studio returned no text.")
        }
        return text
    }

    private func jsonObject(url: URL, method: String, body: [String: Any]?) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 8
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        guard (200..<300).contains(status), let object else {
            throw ProviderBackendError.requestFailed("Local server returned HTTP \(status).")
        }
        return object
    }
}

enum LegalConfig {
    static let privacyURL = URL(string: "https://github.com/arpitagarwal1301/hoverask/blob/main/PRIVACY.md")
    static let termsURL = URL(string: "https://github.com/arpitagarwal1301/hoverask/blob/main/TERMS.md")
    static let contactEmail: String? = nil
}
