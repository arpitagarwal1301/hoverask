import AppKit
import Foundation

enum AssistantEngineError: LocalizedError {
    case emptyPrompt
    case providerFailed(String)
    case timeout(AssistantProvider)

    var errorDescription: String? {
        switch self {
        case .emptyPrompt:
            "Say something first."
        case .providerFailed(let message):
            message
        case .timeout(let provider):
            "\(provider.title) took too long to answer."
        }
    }
}

final class AssistantEngine {
    private let runtimeDirectory: URL
    private let processRunner = ProcessRunner()
    private let byokClient = BYOKClient()
    private let localClient = LocalModelClient()

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HoverAsk/assistant-runtime", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        runtimeDirectory = directory
    }

    func healthCheck() async -> [ProviderHealth] {
        await withTaskGroup(of: ProviderHealth.self) { group in
            for provider in AssistantProvider.allCases {
                group.addTask { [processRunner, localClient] in
                    switch provider.category {
                    case .cli:
                        return processRunner.health(provider: provider)
                    case .local:
                        return await localClient.health(provider: provider, model: provider.defaultModel)
                    case .byok:
                        let connected = BYOKKeychain.hasKey(for: provider)
                        return ProviderHealth(
                            provider: provider,
                            installed: true,
                            authenticated: connected,
                            detail: connected ? "API key stored in macOS Keychain." : "No API key connected."
                        )
                    }
                }
            }

            var results: [ProviderHealth] = []
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.provider.rawValue < $1.provider.rawValue }
        }
    }

    func ask(_ prompt: String, provider selection: ProviderSelection, options: ProviderRuntimeOptions) async throws -> AssistantResult {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw AssistantEngineError.emptyPrompt
        }

        let preparedPrompt = buildPrompt(trimmedPrompt)
        let baseProviderOrder = selection == .auto
            ? AssistantProvider.cliProviders + AssistantProvider.localProviders + AssistantProvider.byokProviders
            : selection.provider.map { [$0] } ?? []
        let providerOrder = selection == .auto ? await readyProviders(from: baseProviderOrder) : baseProviderOrder

        var lastError = ""
        for provider in providerOrder {
            do {
                return try await runProvider(provider, prompt: preparedPrompt, options: options)
            } catch {
                lastError = humanize(provider: provider, error: error.localizedDescription)
            }
        }

        throw AssistantEngineError.providerFailed(lastError.isEmpty ? "No provider could answer." : lastError)
    }

    @MainActor
    func openLogin(provider: AssistantProvider) {
        guard provider.category == .cli else {
            return
        }
        processRunner.openLogin(provider: provider, runtimeDirectory: runtimeDirectory)
    }

    func testProvider(_ provider: AssistantProvider, options: ProviderRuntimeOptions) async -> ProviderTestResult {
        let started = Date()
        do {
            let result = try await runProvider(provider, prompt: "Reply with exactly: HoverAsk provider test OK.", options: options)
            let clean = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return ProviderTestResult(
                provider: provider,
                success: !clean.isEmpty,
                message: clean.isEmpty ? "No response text." : "Test passed: \(clean)",
                duration: Date().timeIntervalSince(started)
            )
        } catch {
            return ProviderTestResult(provider: provider, success: false, message: error.localizedDescription, duration: nil)
        }
    }

    func fetchModels(provider: AssistantProvider) async throws -> [String] {
        switch provider.category {
        case .byok:
            return try await byokClient.fetchModels(provider: provider)
        case .local:
            return try await localClient.fetchModels(provider: provider)
        case .cli:
            return [provider.defaultModel]
        }
    }

    private func runProvider(_ provider: AssistantProvider, prompt: String, options: ProviderRuntimeOptions) async throws -> AssistantResult {
        let started = Date()
        switch provider.category {
        case .cli:
            return try await runCLIProvider(provider, prompt: prompt, options: options, started: started)
        case .local:
            let text = try await localClient.ask(provider: provider, prompt: prompt, model: options.model(for: provider))
            return AssistantResult(provider: provider, text: cleanCliText(text), duration: Date().timeIntervalSince(started))
        case .byok:
            let text = try await byokClient.ask(provider: provider, prompt: prompt, model: options.model(for: provider))
            return AssistantResult(provider: provider, text: cleanCliText(text), duration: Date().timeIntervalSince(started))
        }
    }

    private func runCLIProvider(_ provider: AssistantProvider, prompt: String, options: ProviderRuntimeOptions, started: Date) async throws -> AssistantResult {
        let spec = providerSpec(provider, prompt: prompt, options: options)

        let output = await processRunner.run(
            command: spec.command,
            arguments: spec.arguments,
            standardInput: spec.stdin,
            currentDirectory: runtimeDirectory,
            timeout: 120
        )

        if output.timedOut {
            throw AssistantEngineError.timeout(provider)
        }

        let parsed = AssistantOutputParser.parse(output.stdout)
        let fallbackText = cleanCliText(output.stdout)
        let errorText = cleanCliText(output.stderr)
        let answer = cleanCliText(parsed.isEmpty ? fallbackText : parsed)

        guard output.exitCode == 0, !answer.isEmpty else {
            throw AssistantEngineError.providerFailed(errorText.isEmpty ? fallbackText : errorText)
        }

        return AssistantResult(provider: provider, text: answer, duration: Date().timeIntervalSince(started))
    }

    private func readyProviders(from providers: [AssistantProvider]) async -> [AssistantProvider] {
        let health = await healthCheck()
        let ready = providers.filter { provider in
            guard let match = health.first(where: { $0.provider == provider }) else {
                return false
            }
            return match.installed && match.authenticated
        }
        return ready.isEmpty ? providers : ready
    }

    private func providerSpec(_ provider: AssistantProvider, prompt: String, options: ProviderRuntimeOptions) -> (command: String, arguments: [String], stdin: String?) {
        switch provider {
        case .codex:
            var arguments = [
                "exec",
                "--ephemeral",
                "--skip-git-repo-check",
                "--sandbox",
                "read-only",
                "--color",
                "never",
                "--json",
                "--config",
                "model_reasoning_effort=\"\(options.codexEffort.rawValue)\""
            ]
            if let model = options.codexModel.cliValue {
                arguments.append(contentsOf: ["--model", model])
            }
            arguments.append("-")
            return (
                "codex",
                arguments,
                prompt
            )
        case .claude:
            var arguments = [
                "-p",
                "--output-format",
                "stream-json",
                "--verbose",
                "--include-partial-messages",
                "--no-session-persistence",
                "--permission-mode",
                "dontAsk",
                "--effort",
                options.claudeEffort.rawValue
            ]
            if let model = options.claudeModel.cliValue {
                arguments.append(contentsOf: ["--model", model])
            }
            arguments.append(prompt)
            return (
                "claude",
                arguments,
                nil
            )
        case .cursor:
            return (
                "cursor-agent",
                [
                    "--print",
                    "--mode",
                    "ask",
                    "--output-format",
                    "text",
                    "--trust",
                    "--workspace",
                    runtimeDirectory.path,
                    prompt
                ],
                nil
            )
        case .opencode:
            return (
                "opencode",
                [
                    "run",
                    "--agent",
                    "plan",
                    "--dir",
                    runtimeDirectory.path,
                    prompt
                ],
                nil
            )
        case .antigravity:
            return (
                "agy",
                [
                    "-p",
                    prompt
                ],
                nil
            )
        case .appleIntelligence, .ollama, .lmStudio, .openAI, .anthropic, .gemini, .openRouter, .groq:
            fatalError("Non-CLI provider passed to providerSpec.")
        }
    }

    private func buildPrompt(_ userPrompt: String) -> String {
        [
            "You are a concise floating desktop voice assistant.",
            "Answer conversationally and directly. Keep the response useful when it will be spoken aloud.",
            "Do not edit files, run commands, or inspect the workspace.",
            "If the request needs current private app/page context, say that screen awareness is not enabled in this MVP.",
            "Reply in the same language style as the user. If the user mixes Hindi and English, reply naturally in Hinglish.",
            "",
            "User question:",
            userPrompt
        ].joined(separator: "\n")
    }

    private func humanize(provider: AssistantProvider, error: String) -> String {
        let lower = error.lowercased()
        if lower.contains("auth") || lower.contains("login") || lower.contains("sign in") || lower.contains("not signed in") {
            return "\(provider.title) needs you to sign in from Terminal first."
        }
        if lower.contains("rate limit") || lower.contains("quota") || lower.contains("too many requests") || lower.contains("overloaded") {
            return "\(provider.title) is rate-limited or unavailable right now."
        }
        return error.isEmpty ? "\(provider.title) could not answer this request." : error
    }
}

struct ProcessOutput {
    let stdout: String
    let stderr: String
    let exitCode: Int32
    let timedOut: Bool
}

final class ProcessRunner {
    func health(provider: AssistantProvider) -> ProviderHealth {
        guard provider.category == .cli else {
            return ProviderHealth(provider: provider, installed: false, authenticated: false, detail: "Not a CLI provider.")
        }
        var version = quickRun(command: command(for: provider), arguments: ["--version"], timeout: 4)
        if version.exitCode != 0, provider == .antigravity {
            version = quickRun(command: command(for: provider), arguments: ["--help"], timeout: 4)
        }
        guard version.exitCode == 0 else {
            return ProviderHealth(provider: provider, installed: false, authenticated: false, detail: version.stderr + version.stdout)
        }

        let auth: ProcessOutput = {
            switch provider {
            case .codex:
                quickRun(command: "codex", arguments: ["login", "status"], timeout: 6)
            case .claude:
                quickRun(command: "claude", arguments: ["auth", "status"], timeout: 6)
            case .cursor:
                quickRun(command: "cursor-agent", arguments: ["status"], timeout: 6)
            case .opencode:
                quickRun(command: "opencode", arguments: ["auth", "list"], timeout: 6)
            case .antigravity:
                ProcessOutput(stdout: "Installed. Antigravity CLI command agy was found.", stderr: "", exitCode: 0, timedOut: false)
            case .appleIntelligence, .ollama, .lmStudio, .openAI, .anthropic, .gemini, .openRouter, .groq:
                ProcessOutput(stdout: "", stderr: "Not a CLI provider.", exitCode: 1, timedOut: false)
            }
        }()

        let authText = cleanCliText(auth.stdout + "\n" + auth.stderr)
        let authenticated = isAuthenticated(provider: provider, exitCode: auth.exitCode, text: authText)
        return ProviderHealth(provider: provider, installed: true, authenticated: authenticated, detail: authText)
    }

    @MainActor
    func openLogin(provider: AssistantProvider, runtimeDirectory: URL) {
        let scriptURL = runtimeDirectory.appendingPathComponent("login-\(provider.rawValue).command")
        let executable: String
        let arguments: String

        switch provider {
        case .codex:
            executable = "codex"
            arguments = "login"
        case .claude:
            executable = "claude"
            arguments = "auth login"
        case .cursor:
            executable = "cursor-agent"
            arguments = "login"
        case .opencode:
            executable = "opencode"
            arguments = "auth login"
        case .antigravity:
            executable = "agy"
            arguments = "login"
        case .appleIntelligence, .ollama, .lmStudio, .openAI, .anthropic, .gemini, .openRouter, .groq:
            return
        }

        let script = """
        #!/bin/zsh
        export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
        clear
        echo "Starting \(provider.title) login..."
        echo
        \(executable) \(arguments)
        echo
        echo "\(provider.title) login finished. You can close this Terminal window."
        read -k 1 "?Press any key to close..."
        """

        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
            NSWorkspace.shared.open(scriptURL)
        } catch {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Terminal.app"))
        }
    }

    func run(command: String, arguments: [String], standardInput: String?, currentDirectory: URL, timeout: TimeInterval) async -> ProcessOutput {
        await Task.detached(priority: .userInitiated) {
            self.quickRun(
                command: command,
                arguments: arguments,
                standardInput: standardInput,
                currentDirectory: currentDirectory,
                timeout: timeout
            )
        }.value
    }

    private func quickRun(command: String, arguments: [String], timeout: TimeInterval) -> ProcessOutput {
        quickRun(command: command, arguments: arguments, standardInput: nil, currentDirectory: nil, timeout: timeout)
    }

    private func quickRun(command: String, arguments: [String], standardInput: String? = nil, currentDirectory: URL? = nil, timeout: TimeInterval) -> ProcessOutput {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments
        process.standardOutput = stdout
        process.standardError = stderr
        process.currentDirectoryURL = currentDirectory
        process.environment = environment()

        if standardInput != nil {
            process.standardInput = Pipe()
        }

        do {
            try process.run()
        } catch {
            return ProcessOutput(stdout: "", stderr: error.localizedDescription, exitCode: 127, timedOut: false)
        }

        if let standardInput, let inputPipe = process.standardInput as? Pipe {
            inputPipe.fileHandleForWriting.write(Data(standardInput.utf8))
            try? inputPipe.fileHandleForWriting.close()
        }

        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            process.waitUntilExit()
            group.leave()
        }

        let timedOut = group.wait(timeout: .now() + timeout) == .timedOut
        if timedOut {
            process.terminate()
        }

        let stdoutText = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderrText = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return ProcessOutput(stdout: stdoutText, stderr: stderrText, exitCode: timedOut ? -1 : process.terminationStatus, timedOut: timedOut)
    }

    private func command(for provider: AssistantProvider) -> String {
        switch provider {
        case .codex: "codex"
        case .claude: "claude"
        case .cursor: "cursor-agent"
        case .opencode: "opencode"
        case .antigravity: "agy"
        case .appleIntelligence, .ollama, .lmStudio, .openAI, .anthropic, .gemini, .openRouter, .groq: ""
        }
    }

    private func environment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        let defaultPath = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        let userLocalPath = "\(NSHomeDirectory())/.local/bin"
        env["PATH"] = [env["PATH"], userLocalPath, defaultPath].compactMap { $0 }.joined(separator: ":")
        env["NO_COLOR"] = "1"
        return env
    }
}

private func isAuthenticated(provider: AssistantProvider, exitCode: Int32, text: String) -> Bool {
    guard exitCode == 0 else {
        return false
    }

    let lower = text.lowercased()
    switch provider {
    case .codex:
        return lower.contains("logged in") || !looksLikeAuthError(text)
    case .claude:
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let loggedIn = json["loggedIn"] as? Bool {
            return loggedIn
        }
        return lower.contains("\"loggedin\":true") || !looksLikeAuthError(text)
    case .cursor:
        return lower.contains("logged in") || lower.contains("signed in") || !looksLikeAuthError(text)
    case .opencode:
        return !looksLikeAuthError(text) && !lower.contains("no provider") && !lower.contains("not configured") && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    case .antigravity:
        return true
    case .appleIntelligence, .ollama, .lmStudio, .openAI, .anthropic, .gemini, .openRouter, .groq:
        return false
    }
}

enum AssistantOutputParser {
    static func parse(_ text: String) -> String {
        var tokens = ""
        var finalText = ""

        for line in text.split(whereSeparator: \.isNewline) {
            guard
                let data = String(line).data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                continue
            }

            if let extracted = extract(json) {
                switch extracted.mode {
                case .delta:
                    tokens += extracted.text
                case .snapshot, .final:
                    finalText = extracted.text
                }
            }
        }

        return cleanCliText(finalText.isEmpty ? tokens : finalText)
    }

    private enum Mode {
        case delta
        case snapshot
        case final
    }

    private struct Extracted {
        let mode: Mode
        let text: String
    }

    private static func extract(_ object: [String: Any]) -> Extracted? {
        let type = String(describing: object["type"] ?? object["event"] ?? object["kind"] ?? "").lowercased()

        if let event = object["event"] as? [String: Any], let nested = extract(event) {
            return nested
        }

        if let item = object["item"] as? [String: Any] {
            let itemType = String(describing: item["type"] ?? "").lowercased()
            if let text = collectText(item), itemType.contains("assistant") || itemType.contains("agent_message") || itemType.contains("message") {
                return Extracted(mode: .final, text: text)
            }
        }

        if let delta = firstString(object["delta"], object["text_delta"], object["output_text_delta"]), looksLikeAssistant(type) {
            return Extracted(mode: .delta, text: delta)
        }

        if let deltaObject = object["delta"] as? [String: Any], let text = collectText(deltaObject), looksLikeAssistant(type) {
            return Extracted(mode: .delta, text: text)
        }

        if let result = firstString(object["result"], object["final"], object["output_text"]) {
            return Extracted(mode: .final, text: result)
        }

        if let message = object["message"] as? [String: Any], let text = collectKnownText(message) {
            return Extracted(mode: .snapshot, text: text)
        }

        if let direct = firstString(object["message"], object["content"], object["text"]), looksLikeAssistant(type) {
            return Extracted(mode: .snapshot, text: direct)
        }

        if let text = collectKnownText(object), looksLikeAssistant(type) {
            return Extracted(mode: type.contains("result") ? .final : .snapshot, text: text)
        }

        return nil
    }

    private static func firstString(_ values: Any?...) -> String? {
        for value in values {
            if let string = value as? String, !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return string
            }
        }
        return nil
    }

    private static func looksLikeAssistant(_ type: String) -> Bool {
        type.isEmpty ||
            type.contains("assistant") ||
            type.contains("message") ||
            type.contains("agent") ||
            type.contains("result") ||
            type.contains("output") ||
            type.contains("delta") ||
            type.contains("response")
    }

    private static func collectKnownText(_ object: [String: Any]) -> String? {
        collectText(object["content"]) ?? collectText(object["output"]) ?? collectText(object["item"])
    }

    private static func collectText(_ value: Any?) -> String? {
        if let string = value as? String {
            return string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : string
        }

        if let array = value as? [Any] {
            let parts = array.compactMap { collectText($0) }
            return parts.isEmpty ? nil : parts.joined()
        }

        if let object = value as? [String: Any] {
            if let text = object["text"] as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return text
            }
            if let content = object["content"] as? String, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return content
            }
            return collectText(object["content"])
        }

        return nil
    }
}

func cleanCliText(_ text: String) -> String {
    text
        .replacingOccurrences(of: #"\u{001B}\[[0-9;]*m"#, with: "", options: .regularExpression)
        .replacingOccurrences(of: "\r", with: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

func looksLikeAuthError(_ text: String) -> Bool {
    let lower = text.lowercased()
    return lower.contains("needs login") ||
        lower.contains("not logged in") ||
        lower.contains("not authenticated") ||
        lower.contains("authentication failed") ||
        lower.contains("unauthorized") ||
        lower.contains("not signed in") ||
        lower.contains("sign in") ||
        lower.contains("api key") ||
        lower.contains("subscription")
}
