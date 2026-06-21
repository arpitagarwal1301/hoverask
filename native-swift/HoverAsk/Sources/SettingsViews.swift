import AppKit
import Carbon
import SwiftUI
import UniformTypeIdentifiers

struct SettingsRootView: View {
    @ObservedObject var viewModel: OrbViewModel
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var history: HistoryStore
    @State private var selectedSection: SettingsSection = .overview
    @State private var visibleHistoryCount = 5

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(selectedSection: $selectedSection)
                .environmentObject(settings)
            Divider()
                .overlay(.white.opacity(0.10))
            sectionContent
        }
        .background(SettingsWindowBackground())
        .foregroundStyle(.white.opacity(0.90))
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .overview:
            SettingsScrollContent {
                OverviewSettingsPage(viewModel: viewModel, selectedSection: $selectedSection, visibleHistoryCount: $visibleHistoryCount)
            }
        case .assistant:
            SettingsScrollContent {
                AssistantSettingsPage(viewModel: viewModel)
            }
        case .voice:
            SettingsScrollContent {
                VoiceSettingsPage(viewModel: viewModel)
            }
        case .appearance:
            SettingsScrollContent {
                AppearanceSettingsPage()
            }
        case .providers:
            ProviderSettingsPage(viewModel: viewModel, selectedSection: $selectedSection)
        case .chatHistory:
            SettingsScrollContent {
                ChatHistorySettingsPage(viewModel: viewModel, visibleHistoryCount: $visibleHistoryCount)
            }
        case .advanced:
            SettingsScrollContent {
                AdvancedSettingsPage(viewModel: viewModel)
            }
        }
    }
}

struct SettingsSidebar: View {
    @Binding var selectedSection: SettingsSection
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarGroup("CORE", [.overview, .assistant, .voice, .appearance])
                .padding(.top, 24)
            sidebarGroup("AI", [.providers])
                .padding(.top, 18)
            sidebarGroup("DATA", [.chatHistory])
                .padding(.top, 18)
            sidebarGroup("SYSTEM", [.advanced])
                .padding(.top, 18)
            Spacer(minLength: 18)
            bottomAppCard
                .padding(16)
        }
        .frame(width: 220)
        .background(.black.opacity(0.12))
    }

    private func sidebarGroup(_ title: String, _ sections: [SettingsSection]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))
                .padding(.horizontal, 22)
            ForEach(sections) { section in
                SettingsSidebarRow(section: section, isSelected: selectedSection == section) {
                    selectedSection = section
                }
            }
        }
    }

    private var bottomAppCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                AvatarVisual(style: .orb, size: 42, phase: .idle, motion: .idle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("HoverAsk \(appVersion)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Text("Made for macOS")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            Divider().overlay(.white.opacity(0.10))
            SettingsBottomAction(systemName: "arrow.clockwise", title: "Check updates") {
                openURL("https://github.com/arpitagarwal1301/hoverask/releases")
            }
            SettingsBottomAction(systemName: "info.circle", title: "About") {
                showAbout()
            }
            SettingsBottomAction(systemName: "hand.raised", title: "Privacy") {
                if let url = LegalConfig.privacyURL {
                    NSWorkspace.shared.open(url)
                }
            }
            SettingsBottomAction(systemName: "doc.text", title: "Terms") {
                if let url = LegalConfig.termsURL {
                    NSWorkspace.shared.open(url)
                }
            }
            SettingsBottomAction(systemName: "cup.and.saucer", title: "Support HoverAsk", isDisabled: SupportConfig.supportURL == nil, isProminent: true) {
                if let url = SupportConfig.supportURL {
                    NSWorkspace.shared.open(url)
                }
            }
            .help(SupportConfig.supportURL == nil ? "Support link is not configured yet." : "Support HoverAsk")
        }
        .padding(14)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(0.11), lineWidth: 1))
    }
}

struct SettingsSidebarRow: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 23)
                Text(section.title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium, design: .rounded))
                Spacer()
            }
            .foregroundStyle(isSelected ? .white.opacity(0.96) : .white.opacity(0.72))
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.cyan.opacity(0.18) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.cyan.opacity(0.35) : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .padding(.horizontal, 14)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsScrollContent<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(showsIndicators: true) {
            content
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct OverviewSettingsPage: View {
    @ObservedObject var viewModel: OrbViewModel
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var history: HistoryStore
    @Binding var selectedSection: SettingsSection
    @Binding var visibleHistoryCount: Int

    private var localProviders: [LocalProviderHealth] {
        LocalProviderService.health()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                SettingsPageHeader(title: "Overview", subtitle: "Everything important at a glance.")
                Spacer()
                avatarHero
            }

            SettingsGroup {
                SettingsStatusRow(icon: "macwindow", title: "Floating assistant", detail: "\(settings.avatarStyle.title) is selected.", status: "Visible", tone: .success, actionSystemName: "pencil", actionLabel: "Edit appearance") {
                    selectedSection = .appearance
                }
                SettingsStatusRow(icon: "mic", title: "Microphone", detail: "Allowed for voice input.", status: "Allowed", tone: .success, actionSystemName: "speaker.wave.2", actionLabel: "Test voice") {
                    viewModel.previewVoice()
                }
                SettingsStatusRow(icon: "waveform", title: "Speech recognition", detail: "Ready for English and Hinglish.", status: "Allowed", tone: .success, actionSystemName: "pencil", actionLabel: "Edit voice") {
                    selectedSection = .voice
                }
                SettingsStatusRow(icon: "point.3.connected.trianglepath.dotted", title: "Active route", detail: "Where your questions are answered.", status: "\(settings.provider.title) · Best available", tone: .info, actionSystemName: "pencil", actionLabel: "Edit providers") {
                    selectedSection = .providers
                }
                SettingsStatusRow(icon: "apple.logo", title: "Apple Intelligence", detail: "On-device model availability.", status: appleStatusText, tone: appleStatusTone)
                SettingsStatusRow(icon: "powerplug", title: "Providers", detail: providerRefreshDetail, status: "\(readyCliCount) CLI ready · \(localStatusSummary)", tone: readyCliCount > 0 ? .success : .warning, actionSystemName: viewModel.isRefreshingProviderHealth ? "hourglass" : "arrow.clockwise", actionLabel: "Refresh providers", actionDisabled: viewModel.isRefreshingProviderHealth) {
                    viewModel.refreshHealth()
                }
                SettingsStatusRow(icon: "clock.arrow.circlepath", title: "Chat history", detail: "Local transcripts and replies.", status: "\(history.items.count) saved · \(formattedHistorySize)", tone: .neutral, actionSystemName: "pencil", actionLabel: "Open chat history") {
                    selectedSection = .chatHistory
                }
                SettingsStatusRow(icon: "key", title: "BYOK", detail: "API keys will be stored in Keychain.", status: "Not configured", tone: .warning, actionSystemName: "pencil", actionLabel: "Open providers") {
                    selectedSection = .providers
                }
            }

            privacyStrip
        }
    }

    private var avatarHero: some View {
        HStack(alignment: .bottom, spacing: 12) {
            AvatarVisual(style: .orb, size: 76, phase: .idle, motion: .idle)
            AvatarVisual(style: .dog, size: 88, phase: .idle, motion: .idle)
            AvatarVisual(style: .cat, size: 62, phase: .idle, motion: .idle)
        }
        .padding(.trailing, 24)
        .padding(.top, 4)
        .shadow(color: .cyan.opacity(0.18), radius: 22, x: 0, y: 12)
    }

    private var privacyStrip: some View {
        HStack(spacing: 12) {
            SettingsGlyph(systemName: "shield.checkerboard", tone: .info)
            Text("Privacy by design")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.cyan.opacity(0.92))
            Text("·")
                .foregroundStyle(.white.opacity(0.28))
            Text("No screenshots")
            Text("·")
                .foregroundStyle(.white.opacity(0.28))
            Text("Keys will use Keychain")
            Text("·")
                .foregroundStyle(.white.opacity(0.28))
            Text("Apple Intelligence/local providers stay on this Mac")
        }
        .font(.system(size: 13, weight: .medium, design: .rounded))
        .foregroundStyle(.white.opacity(0.76))
        .padding(14)
        .background(.cyan.opacity(0.075), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(.cyan.opacity(0.24), lineWidth: 1))
        .shadow(color: .cyan.opacity(0.10), radius: 14, x: 0, y: 8)
    }

    private var readyCliCount: Int {
        viewModel.providerHealth.filter { $0.installed && $0.authenticated }.count
    }

    private var appleStatusText: String {
        localProviders.first(where: { $0.kind == .appleIntelligence })?.status.title ?? "Checking"
    }

    private var appleStatusTone: SettingsStatusTone {
        let isAvailable = localProviders.first(where: { $0.kind == .appleIntelligence })?.status.isPositive ?? false
        return isAvailable ? .success : .warning
    }

    private var localStatusSummary: String {
        let appleReady = localProviders.first(where: { $0.kind == .appleIntelligence })?.status.isPositive ?? false
        return appleReady ? "Apple local ready" : "local planned"
    }

    private var providerRefreshDetail: String {
        if viewModel.isRefreshingProviderHealth {
            return "Refreshing connected answer sources."
        }
        return "Connected answer sources · \(relativeRefreshText(viewModel.providerHealthLastRefreshed))"
    }
}

struct AssistantSettingsPage: View {
    @ObservedObject var viewModel: OrbViewModel
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsPageHeader(title: "AI Assistant", subtitle: "Set the default answer route and conversation behavior.")
            SettingsGroup(title: "Default behavior") {
                SettingsPickerRow(title: "Provider", detail: "Auto or a ready/enabled answer source.", selection: $settings.provider) {
                    ForEach(providerPickerOptions) { provider in
                        Text(provider.title).tag(provider)
                    }
                }
                SettingsToggleRow(title: "Keep listening after answers", detail: "Restart listening after a reply finishes.", isOn: $settings.continuousConversationEnabled)
            }
            SettingsGroup(title: "Answer route") {
                SettingsStatusRow(icon: "point.3.connected.trianglepath.dotted", title: "Current route", detail: "Auto tries ready sources in order.", status: settings.provider.title, tone: .info)
                SettingsActionButton("Refresh provider status", systemName: "arrow.clockwise") {
                    viewModel.refreshHealth()
                }
            }
        }
    }

    private var providerPickerOptions: [ProviderSelection] {
        var options: [ProviderSelection] = [.auto]
        for provider in settings.normalizedRouteOrder {
            if providerIsReady(provider) {
                options.append(provider.selection)
            }
        }
        if let currentProvider = settings.provider.provider, !options.contains(currentProvider.selection) {
            options.append(currentProvider.selection)
        }
        return options.reduce(into: [ProviderSelection]()) { result, selection in
            if !result.contains(selection) {
                result.append(selection)
            }
        }
    }

    private func providerIsReady(_ provider: AssistantProvider) -> Bool {
        guard !settings.disabledProviders.contains(provider),
              let health = viewModel.providerHealth.first(where: { $0.provider == provider }),
              health.installed,
              health.authenticated
        else {
            return false
        }
        switch provider.category {
        case .cli:
            return true
        case .local, .byok:
            return !settings.providerModelChoice(for: provider).modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

struct VoiceSettingsPage: View {
    @ObservedObject var viewModel: OrbViewModel
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "waveform")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.cyan.opacity(0.82))
                SettingsPageHeader(title: "Voice", subtitle: "Test and configure how HoverAsk listens and speaks.")
            }
            SettingsGroup(title: "Input tests") {
                VoiceTestRow(
                    icon: "mic",
                    title: "Test microphone",
                    detail: "Checks access and input level.",
                    state: viewModel.microphoneTestState,
                    buttonTitle: "Test mic",
                    action: { viewModel.testMicrophone() }
                )
                VoiceTestRow(
                    icon: "waveform",
                    title: "Test speech recognition",
                    detail: "Records a short sample and shows the transcript.",
                    state: viewModel.speechRecognitionTestState,
                    buttonTitle: "Test speech",
                    action: { viewModel.testSpeechRecognition() }
                )
            }
            HStack(alignment: .top, spacing: 18) {
                SettingsGroup(title: "Listening") {
                SettingsPickerRow(title: "Speech input", detail: "Recognition language for voice prompts.", selection: $settings.voiceLocale) {
                    ForEach(VoiceLocale.allCases) { locale in
                        Text(locale.title).tag(locale)
                    }
                }
                SettingsPickerRow(title: "Listen mode", detail: "How the orb starts and stops recording.", selection: $settings.listenMode) {
                    ForEach(ListenMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                    SettingsStatusRow(icon: "clock", title: "Silence wait before send", detail: "Wait this long after you stop speaking.", status: "5 sec", tone: .info)
                    SettingsToggleRow(title: "Continuous conversation", detail: "Keep listening after replies.", isOn: $settings.continuousConversationEnabled)
                }
                SettingsGroup(title: "Spoken replies") {
                SettingsPickerRow(title: "Reply voice", detail: "Voice used for spoken answers.", selection: $settings.speechVoice) {
                    ForEach(SpeechVoicePreset.allCases) { voice in
                        Text(voice.title).tag(voice)
                    }
                }
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Voice pace")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Text("Speed for spoken replies.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.50))
                    }
                    Spacer()
                    Slider(value: $settings.speechRate, in: 0.34...0.58)
                        .frame(width: 210)
                    SettingsActionButton("Preview") {
                        viewModel.previewVoice()
                    }
                }
                .frame(minHeight: 46)
                SettingsToggleRow(title: "Speak answers aloud", detail: "Read provider replies in a conversational voice.", isOn: $settings.spokenRepliesEnabled)
                }
            }
        }
    }
}

private struct VoiceTestRow: View {
    let icon: String
    let title: String
    let detail: String
    let state: VoiceTestState
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            SettingsGlyph(systemName: icon, tone: tone)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.52))
            }
            Spacer()
            stateView
                .frame(width: 250, alignment: .trailing)
            SettingsActionButton(buttonTitle, action: action)
        }
        .padding(.vertical, 8)
        SettingsDivider()
    }

    @ViewBuilder
    private var stateView: some View {
        switch state {
        case .microphoneLevel(let level):
            HStack(spacing: 9) {
                MicrophoneLevelMeter(level: level)
                statusLabel("Listening", tone: .success)
            }
        case .testing(let text):
            statusPill(text, tone: .info)
        case .passed(let text):
            statusPill(text, tone: .success)
        case .failed(let text):
            statusPill(text, tone: .warning)
        case .idle:
            statusLabel("Ready", tone: .success)
        }
    }

    private var tone: SettingsStatusTone {
        switch state {
        case .failed: .warning
        case .testing, .microphoneLevel: .info
        case .passed, .idle: .success
        }
    }

    private func statusLabel(_ text: String, tone: SettingsStatusTone) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(tone.color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white.opacity(0.72))
    }

    private func statusPill(_ text: String, tone: SettingsStatusTone) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(tone.color.opacity(0.95))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tone.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(tone.color.opacity(0.18), lineWidth: 1))
    }
}

private struct MicrophoneLevelMeter: View {
    let level: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<14, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Double(index) / 14.0 < level ? Color.green.opacity(0.88) : Color.white.opacity(0.14))
                    .frame(width: 5, height: CGFloat(8 + min(index, 8) * 2))
            }
        }
        .frame(height: 28)
    }
}

struct AppearanceSettingsPage: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsPageHeader(title: "Avatar", subtitle: "Tune the floating companion and attached chat.")
            SettingsGroup(title: "Assistant look") {
                HStack(spacing: 18) {
                    AvatarPreview(style: .orb, selected: settings.avatarStyle == .orb) {
                        settings.avatarStyle = .orb
                    }
                    AvatarPreview(style: .dog, selected: settings.avatarStyle == .dog) {
                        settings.avatarStyle = .dog
                    }
                    AvatarPreview(style: .cat, selected: settings.avatarStyle == .cat) {
                        settings.avatarStyle = .cat
                    }
                    Spacer()
                }
                SettingsPickerRow(title: "Assistant", detail: "Main floating avatar.", selection: $settings.avatarStyle) {
                    ForEach(AvatarStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                SettingsPickerRow(title: "Companion movement", detail: "Optional motion for dog/cat avatars.", selection: $settings.companionMovementMode) {
                    ForEach(CompanionMovementMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                SettingsPickerRow(title: "Chat bubble", detail: "Preferred bubble placement near the avatar.", selection: $settings.bubblePlacement) {
                    ForEach(BubblePlacement.allCases) { placement in
                        Text(placement.title).tag(placement)
                    }
                }
            }
        }
    }
}

private enum ProviderRouteGroup: String, CaseIterable, Identifiable {
    case cli
    case local
    case byok

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cli: "CLI"
        case .local: "Local"
        case .byok: "BYOK"
        }
    }

    var shortTitle: String {
        switch self {
        case .cli: "CLI"
        case .local: "Local"
        case .byok: "BYOK"
        }
    }

    var providers: [AssistantProvider] {
        switch self {
        case .cli: AssistantProvider.cliProviders
        case .local: AssistantProvider.localProviders
        case .byok: AssistantProvider.byokProviders
        }
    }

    static func group(for provider: AssistantProvider) -> ProviderRouteGroup {
        switch provider.category {
        case .cli: .cli
        case .local: .local
        case .byok: .byok
        }
    }
}

struct ProviderSettingsPage: View {
    @ObservedObject var viewModel: OrbViewModel
    @EnvironmentObject private var settings: SettingsStore
    @Binding var selectedSection: SettingsSection
    @State private var isEditingRouteOrder = false
    @State private var expandedProviderBuckets: Set<ProviderRouteGroup> = []
    @State private var primaryRouteGroup: ProviderRouteGroup = .cli
    @State private var firstFallbackGroup: ProviderRouteGroup = .local
    @State private var finalFallbackGroup: ProviderRouteGroup = .byok
    @State private var activeDraggedProvider: AssistantProvider?
    @State private var activeRouteDragProvider: AssistantProvider?
    @State private var isRouteInfoPresented = false

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        SettingsPageHeader(title: "Providers", subtitle: "Choose where HoverAsk answers come from without managing one huge list.")
                        Spacer()
                        SettingsActionButton("Reset to defaults", systemName: "arrow.clockwise") {
                            resetProviderDefaults()
                        }
                    }
                    routeBuilder
                    providerBucket("CLI", detail: "Use logged-in command-line accounts for fast, reliable replies.", providers: AssistantProvider.cliProviders)
                    providerBucket("Local", detail: "Answers can stay on this Mac when available.", providers: AssistantProvider.localProviders)
                    providerBucket("BYOK", detail: "Bring your own API keys. Keys are stored in macOS Keychain.", providers: AssistantProvider.byokProviders)
                    providerPrivacyFooter
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
            routeInspector
                .frame(width: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var routeBuilder: some View {
        SettingsGroup(title: nil) {
            HStack(spacing: 10) {
                let routeControlsEnabled = settings.provider == .auto
                Text("Use")
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .fixedSize()
                Picker("Provider", selection: $settings.provider) {
                    ForEach(providerPickerOptions) { selection in
                        Text(selection.title).tag(selection)
                    }
                }
                .labelsHidden()
                .frame(width: 115)
                Text("Strategy")
                    .foregroundStyle(.white.opacity(0.60))
                    .lineLimit(1)
                    .fixedSize()
                routeGroupPicker(selection: primaryRouteBinding, width: 84)
                    .disabled(!routeControlsEnabled)
                    .opacity(routeControlsEnabled ? 1 : 0.45)
                Text("Fallback")
                    .foregroundStyle(.white.opacity(0.60))
                    .lineLimit(1)
                    .fixedSize()
                routeGroupPicker(selection: firstFallbackBinding, width: 84)
                    .disabled(!routeControlsEnabled)
                    .opacity(routeControlsEnabled ? 1 : 0.45)
                Text("Then")
                    .foregroundStyle(.white.opacity(0.60))
                    .lineLimit(1)
                    .fixedSize()
                routeGroupPicker(selection: finalFallbackBinding, width: 84)
                    .disabled(!routeControlsEnabled)
                    .opacity(routeControlsEnabled ? 1 : 0.45)
                Spacer()
            }
            .font(.system(size: 13, weight: .medium, design: .rounded))
            if settings.provider != .auto {
                Text("Fallback routing is used only when provider is set to Auto.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
            }
        }
    }

    private func routeGroupPicker(selection: Binding<ProviderRouteGroup>, width: CGFloat) -> some View {
        Picker("Route group", selection: selection) {
            ForEach(ProviderRouteGroup.allCases) { group in
                Text(group.title).tag(group)
            }
        }
        .labelsHidden()
        .frame(width: width)
    }

    private var primaryRouteBinding: Binding<ProviderRouteGroup> {
        Binding(
            get: { primaryRouteGroup },
            set: { group in
                primaryRouteGroup = group
                ensureUniqueRouteGroups()
                applyRouteGroupPreset()
            }
        )
    }

    private var firstFallbackBinding: Binding<ProviderRouteGroup> {
        Binding(
            get: { firstFallbackGroup },
            set: { group in
                firstFallbackGroup = group
                ensureUniqueRouteGroups()
                applyRouteGroupPreset()
            }
        )
    }

    private var finalFallbackBinding: Binding<ProviderRouteGroup> {
        Binding(
            get: { finalFallbackGroup },
            set: { group in
                finalFallbackGroup = group
                ensureUniqueRouteGroups()
                applyRouteGroupPreset()
            }
        )
    }

    private func ensureUniqueRouteGroups() {
        var chosen: [ProviderRouteGroup] = []
        for group in [primaryRouteGroup, firstFallbackGroup, finalFallbackGroup] where !chosen.contains(group) {
            chosen.append(group)
        }
        for group in ProviderRouteGroup.allCases where !chosen.contains(group) {
            chosen.append(group)
        }
        primaryRouteGroup = chosen[0]
        firstFallbackGroup = chosen[1]
        finalFallbackGroup = chosen[2]
    }

    private func applyRouteGroupPreset() {
        settings.providerRouteOrder = [primaryRouteGroup, firstFallbackGroup, finalFallbackGroup].flatMap(\.providers)
    }

    private func providerBucket(_ title: String, detail: String, providers: [AssistantProvider]) -> some View {
        let group = providers.first.map(ProviderRouteGroup.group(for:)) ?? .cli
        let orderedProviders = orderedProvidersForBucket(providers)
        let isExpanded = expandedProviderBuckets.contains(group)
        let visibleProviders = isExpanded ? orderedProviders : Array(orderedProviders.prefix(3))
        let hiddenCount = max(orderedProviders.count - visibleProviders.count, 0)
        let readyCount = providers.filter { readiness(for: $0).isReady }.count
        let setupCount = providers.count - readyCount
        return SettingsGroup(title: nil) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Circle()
                    .fill(readyCount > 0 ? SettingsStatusTone.success.color : SettingsStatusTone.warning.color)
                    .frame(width: 8, height: 8)
                Text("\(readyCount) ready")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(readyCount > 0 ? SettingsStatusTone.success.color : SettingsStatusTone.warning.color)
                if setupCount > 0 {
                    Text("· \(setupCount) needs setup")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
                Spacer()
                if orderedProviders.count > 3 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            if isExpanded {
                                expandedProviderBuckets.remove(group)
                            } else {
                                expandedProviderBuckets.insert(group)
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(isExpanded ? "Show top 3" : "Show all (\(hiddenCount))")
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.cyan.opacity(0.82))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(detail)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
            VStack(spacing: 0) {
                ForEach(visibleProviders) { provider in
                    providerRow(provider)
                }
            }
            .background(.white.opacity(0.026), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.white.opacity(0.07), lineWidth: 1))
        }
    }

    private func orderedProvidersForBucket(_ providers: [AssistantProvider]) -> [AssistantProvider] {
        let route = settings.normalizedRouteOrder
        return providers.sorted { lhs, rhs in
            let lhsRoute = route.firstIndex(of: lhs) ?? Int.max
            let rhsRoute = route.firstIndex(of: rhs) ?? Int.max
            if lhsRoute != rhsRoute {
                return lhsRoute < rhsRoute
            }
            let lhsDefault = AssistantProvider.defaultRouteOrder.firstIndex(of: lhs) ?? Int.max
            let rhsDefault = AssistantProvider.defaultRouteOrder.firstIndex(of: rhs) ?? Int.max
            return lhsDefault < rhsDefault
        }
    }

    @ViewBuilder
    private func providerRow(_ provider: AssistantProvider) -> some View {
        let readiness = readiness(for: provider)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if isEditingRouteOrder {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.cyan.opacity(0.72))
                        .frame(width: 12)
                }
                Image(systemName: providerIcon(provider))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.76))
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                Circle()
                    .fill(tone(for: readiness).color)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    Text(providerSubtitle(provider))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.48))
                        .lineLimit(1)
                }
                .frame(width: provider == .appleIntelligence ? 150 : 118, alignment: .leading)
                Spacer()
                statusChip(readiness)
                    .frame(width: 92, alignment: .leading)
                providerModelControls(provider)
                    .frame(width: provider == .appleIntelligence ? 158 : (provider.category == .cli ? 188 : 230), alignment: .leading)
                primaryProviderAction(provider)
                    .frame(width: 72)
                providerOverflowMenu(provider)
            }

            if let result = viewModel.providerTestResults[provider] {
                HStack(spacing: 8) {
                    Image(systemName: result.success ? "checkmark.circle" : "exclamationmark.triangle")
                    Text(result.message)
                        .lineLimit(2)
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(result.success ? SettingsStatusTone.success.color : SettingsStatusTone.warning.color)
                .padding(.leading, 48)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .onDrag {
            activeDraggedProvider = provider
            activeRouteDragProvider = nil
            return NSItemProvider(object: routeDragPayload(provider, origin: "source") as NSString)
        }
        .opacity(isEditingRouteOrder ? 1 : 1)
        SettingsDivider()
            .padding(.leading, 50)
    }

    private func statusChip(_ readiness: ProviderReadinessState) -> some View {
        Text(statusTitle(for: readiness))
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(tone(for: readiness).color.opacity(0.96))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tone(for: readiness).color.opacity(0.10), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(tone(for: readiness).color.opacity(0.22), lineWidth: 1))
    }

    @ViewBuilder
    private func primaryProviderAction(_ provider: AssistantProvider) -> some View {
        let readiness = readiness(for: provider)
        switch readiness {
        case .disabled:
            SettingsActionButton("Enable") { viewModel.reconnectProvider(provider) }
        case .missing:
            SettingsActionButton("Info") { openDocs(provider) }
        case .needsLogin:
            SettingsActionButton("Login") { viewModel.login(provider: provider) }
        case .keyRequired:
            SettingsActionButton("Connect") { promptForAPIKey(provider) }
        case .modelRequired:
            SettingsActionButton("Models") { viewModel.fetchModels(for: provider) }
        case .ready:
            SettingsActionButton("Test") { viewModel.testProvider(provider) }
        case .failed:
            SettingsActionButton("Retry") { viewModel.testProvider(provider) }
        }
    }

    private func providerOverflowMenu(_ provider: AssistantProvider) -> some View {
        Menu {
            Button("Test") { viewModel.testProvider(provider) }
                .disabled(!readiness(for: provider).isReady)
            Button("Fetch models") { viewModel.fetchModels(for: provider) }
                .disabled(provider.category == .cli && provider != .codex && provider != .claude)
            if provider.category == .cli {
                Button("Re-login") { viewModel.login(provider: provider) }
            }
            if provider.category == .byok {
                Button("Connect / Replace key") { promptForAPIKey(provider) }
                Button("Delete key") { confirmDeleteKey(provider) }
                    .disabled(!BYOKKeychain.hasKey(for: provider))
            }
            Divider()
            if settings.disabledProviders.contains(provider) {
                Button("Enable in HoverAsk") { viewModel.reconnectProvider(provider) }
            } else {
                Button("Disconnect from HoverAsk") { viewModel.disconnectProvider(provider) }
            }
            Divider()
            Button("Provider info") { openDocs(provider) }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.74))
                .frame(width: 30, height: 28)
                .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
        .frame(width: 32)
    }

    @ViewBuilder
    private func providerModelControls(_ provider: AssistantProvider) -> some View {
        let choices = modelChoices(for: provider)
        HStack(spacing: 8) {
            if provider == .appleIntelligence {
                SettingsPill("Apple Default", systemName: nil)
                    .frame(width: 128, alignment: .leading)
            } else if choices.isEmpty {
                SettingsPill(settings.providerModelChoice(for: provider).modelID, systemName: nil)
                    .frame(width: 150, alignment: .leading)
            } else {
                Picker("Model", selection: choiceBinding(for: provider)) {
                    ForEach(choices) { choice in
                        Text(choice.displayTitle).tag(choice.id)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
            }
            if provider.category != .cli && provider != .appleIntelligence {
                TextField(provider.defaultModel, text: modelIDBinding(for: provider))
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 8)
                    .frame(width: 84, height: 28)
                    .background(.white.opacity(0.052), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))
            }
        }
        .accessibilityLabel("Model")
    }

    private var routeInspector: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(isEditingRouteOrder ? "Fallback route" : "Selected route")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    routeInfoButton
                }
                Text(isEditingRouteOrder ? "Drag sources into Auto fallback." : "HoverAsk will try each source in this order.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
            }
            SettingsDivider()
            HStack {
                Text("Fallback order")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Spacer()
                routeEditToggle
            }
            ScrollView(showsIndicators: isEditingRouteOrder) {
                VStack(alignment: .leading, spacing: isEditingRouteOrder ? 9 : 13) {
                    ForEach(Array(routeOrderForDisplay.enumerated()), id: \.element) { index, provider in
                        if isEditingRouteOrder {
                            routeEditChip(index: index + 1, provider: provider)
                        } else {
                            routeStep(index: index + 1, provider: provider)
                        }
                    }
                }
            }
            .frame(maxHeight: isEditingRouteOrder ? 286 : 310)
            HStack(spacing: 6) {
                routeActionButton("Test", systemName: "waveform", help: "Test route") {
                    if let firstReady = settings.normalizedRouteOrder.first(where: { readiness(for: $0).isReady }) {
                        viewModel.testProvider(firstReady)
                    }
                }
                routeActionButton("Reset", systemName: "arrow.counterclockwise", help: "Reset fallback route") {
                    resetProviderDefaults()
                }
                routeActionButton("Refresh", systemName: "arrow.clockwise", help: "Refresh provider status") {
                    viewModel.refreshHealth()
                }
            }
            if isEditingRouteOrder {
                routeAddTarget
            }
            if isEditingRouteOrder && activeRouteDragProvider != nil {
                routeRemoveDropZone
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .background(.black.opacity(0.11))
    }

    private var routeInfoButton: some View {
        Button {
            isRouteInfoPresented.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.cyan.opacity(0.92))
                .frame(width: 20, height: 20)
                .background(.cyan.opacity(0.08), in: Circle())
                .overlay(Circle().stroke(.cyan.opacity(0.24), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help("About fallback routing")
        .popover(isPresented: $isRouteInfoPresented, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Label("About routing", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                Text("Auto skips disabled, missing, unkeyed, and model-missing sources, then tries the fallback route from top to bottom.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(width: 260, alignment: .leading)
            .background(Color(red: 0.03, green: 0.09, blue: 0.10).opacity(0.96))
        }
    }

    private var routeEditToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                isEditingRouteOrder.toggle()
                activeDraggedProvider = nil
                activeRouteDragProvider = nil
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isEditingRouteOrder ? "checkmark" : "pencil")
                    .font(.system(size: 10, weight: .bold))
                Text(isEditingRouteOrder ? "Done" : "Edit route")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(isEditingRouteOrder ? Color.black.opacity(0.84) : Color.cyan.opacity(0.92))
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                isEditingRouteOrder ? Color.cyan.opacity(0.82) : Color.cyan.opacity(0.09),
                in: Capsule()
            )
            .overlay(Capsule().stroke(Color.cyan.opacity(isEditingRouteOrder ? 0.16 : 0.26), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help(isEditingRouteOrder ? "Done editing route" : "Edit fallback route")
    }

    private func routeActionButton(_ title: String, systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
            }
            .foregroundStyle(.white.opacity(0.86))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.white.opacity(0.060), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private var routeOrderForDisplay: [AssistantProvider] {
        isEditingRouteOrder ? settings.normalizedRouteOrder : Array(settings.normalizedRouteOrder.prefix(7))
    }

    private func routeStep(index: Int, provider: AssistantProvider) -> some View {
        HStack(spacing: 10) {
            Text("\(index)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.cyan.opacity(0.92))
                .frame(width: 28, height: 28)
                .background(.cyan.opacity(0.08), in: Circle())
                .overlay(Circle().stroke(.cyan.opacity(0.55), lineWidth: 1))
            Image(systemName: providerIcon(provider))
                .frame(width: 22)
                .foregroundStyle(.white.opacity(settings.disabledProviders.contains(provider) ? 0.34 : 0.76))
            VStack(alignment: .leading, spacing: 1) {
                Text(provider.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(settings.disabledProviders.contains(provider) ? 0.42 : 0.88))
                Text(statusTitle(for: readiness(for: provider)))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(tone(for: readiness(for: provider)).color)
            }
            Spacer()
        }
    }

    private func routeEditChip(index: Int, provider: AssistantProvider) -> some View {
        HStack(spacing: 9) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.cyan.opacity(0.76))
                .frame(width: 14)
            Text("\(index)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.cyan.opacity(0.92))
                .frame(width: 22, height: 22)
                .background(.cyan.opacity(0.08), in: Circle())
                .overlay(Circle().stroke(.cyan.opacity(0.48), lineWidth: 1))
            Image(systemName: providerIcon(provider))
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 18)
                .foregroundStyle(.white.opacity(0.76))
            VStack(alignment: .leading, spacing: 1) {
                Text(provider.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Text(shortModel(settings.providerModelChoice(for: provider).modelID))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(1)
            }
            Spacer()
            Circle()
                .fill(tone(for: readiness(for: provider)).color)
                .frame(width: 7, height: 7)
            Button {
                removeProviderFromRoute(provider)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(settings.normalizedRouteOrder.count <= 1 ? 0.26 : 0.72))
                    .frame(width: 20, height: 20)
                    .background(.white.opacity(0.060), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.11), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(settings.normalizedRouteOrder.count <= 1)
            .help("Remove from route")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))
        .contentShape(Rectangle())
        .onDrag {
            activeDraggedProvider = provider
            activeRouteDragProvider = provider
            return NSItemProvider(object: routeDragPayload(provider, origin: "route") as NSString)
        }
        .onDrop(of: [.plainText], isTargeted: nil) { providers in
            handleProviderDrop(providers, before: provider)
        }
    }

    private var routeAddTarget: some View {
        ZStack {
            HStack(spacing: 9) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.cyan.opacity(0.9))
                    .frame(width: 22, height: 22)
                    .background(.cyan.opacity(0.08), in: Circle())
                    .overlay(Circle().stroke(.cyan.opacity(0.36), lineWidth: 1))
                Text("+ Add provider to fallback")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.cyan.opacity(0.70))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(.cyan.opacity(0.070), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.cyan.opacity(0.36), style: StrokeStyle(lineWidth: 1, dash: [6, 4])))

            Menu {
                let missing = providersNotInRoute
                if missing.isEmpty {
                    Button("All sources are already in route") {}
                        .disabled(true)
                } else {
                    ForEach(missing) { provider in
                        Button("Add \(provider.title)") {
                            addProviderToRoute(provider, before: nil)
                        }
                    }
                }
            } label: {
                Rectangle()
                    .fill(Color.white.opacity(0.001))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .opacity(0.02)
        }
        .onDrop(of: [.plainText], isTargeted: nil) { providers in
            handleProviderDrop(providers, before: nil)
        }
    }

    private var routeRemoveDropZone: some View {
        HStack(spacing: 10) {
            Image(systemName: "minus.circle")
                .font(.system(size: 14, weight: .bold))
            Text("Drag here to remove")
                .font(.system(size: 12, weight: .bold, design: .rounded))
            Spacer()
        }
        .foregroundStyle(.orange.opacity(0.86))
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(.orange.opacity(0.075), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.orange.opacity(0.30), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
        .onDrop(of: [.plainText], isTargeted: nil) { providers in
            handleRemoveDrop(providers)
        }
    }

    private var providersNotInRoute: [AssistantProvider] {
        AssistantProvider.defaultRouteOrder.filter { !settings.normalizedRouteOrder.contains($0) }
    }

    private func routeDragPayload(_ provider: AssistantProvider, origin: String) -> String {
        "hoverask-provider:\(origin):\(provider.rawValue)"
    }

    private func handleProviderDrop(_ itemProviders: [NSItemProvider], before targetProvider: AssistantProvider?) -> Bool {
        guard let itemProvider = itemProviders.first else {
            return false
        }
        itemProvider.loadObject(ofClass: NSString.self) { object, _ in
            guard let payload = object as? NSString,
                  let provider = providerFromDragPayload(payload)
            else {
                return
            }
            DispatchQueue.main.async {
                addProviderToRoute(provider, before: targetProvider)
                activeDraggedProvider = nil
                activeRouteDragProvider = nil
            }
        }
        return true
    }

    private func handleRemoveDrop(_ itemProviders: [NSItemProvider]) -> Bool {
        guard let itemProvider = itemProviders.first else {
            return false
        }
        itemProvider.loadObject(ofClass: NSString.self) { object, _ in
            guard let payload = object as? NSString,
                  (payload as String).contains(":route:"),
                  let provider = providerFromDragPayload(payload)
            else {
                return
            }
            DispatchQueue.main.async {
                removeProviderFromRoute(provider)
                activeDraggedProvider = nil
                activeRouteDragProvider = nil
            }
        }
        return true
    }

    private func providerFromDragPayload(_ payload: NSString) -> AssistantProvider? {
        let parts = (payload as String).split(separator: ":")
        guard parts.count == 3,
              parts[0] == "hoverask-provider"
        else {
            return nil
        }
        return AssistantProvider(rawValue: String(parts[2]))
    }

    private func addProviderToRoute(_ provider: AssistantProvider, before targetProvider: AssistantProvider?) {
        var order = settings.normalizedRouteOrder.filter { $0 != provider }
        if let targetProvider, let targetIndex = order.firstIndex(of: targetProvider) {
            order.insert(provider, at: targetIndex)
        } else {
            order.append(provider)
        }
        settings.providerRouteOrder = order
    }

    private func removeProviderFromRoute(_ provider: AssistantProvider) {
        let order = settings.normalizedRouteOrder
        guard order.count > 1 else {
            return
        }
        settings.providerRouteOrder = order.filter { $0 != provider }
    }

    private var providerPickerOptions: [ProviderSelection] {
        var options: [ProviderSelection] = [.auto]
        for provider in settings.normalizedRouteOrder where readiness(for: provider).isReady {
            options.append(provider.selection)
        }
        if let currentProvider = settings.provider.provider, !options.contains(currentProvider.selection) {
            options.append(currentProvider.selection)
        }
        return options
    }

    private func readiness(for provider: AssistantProvider) -> ProviderReadinessState {
        if settings.disabledProviders.contains(provider) {
            return .disabled
        }
        let model = settings.providerModelChoice(for: provider).modelID.trimmingCharacters(in: .whitespacesAndNewlines)
        let health = health(for: provider)
        switch provider.category {
        case .cli:
            guard let health else { return .failed("Checking") }
            if !health.installed { return .missing }
            if !health.authenticated { return .needsLogin }
            return .ready
        case .local:
            guard let health else { return .failed("Checking") }
            if !health.authenticated { return .failed(health.detail) }
            if model.isEmpty { return .modelRequired }
            return .ready
        case .byok:
            if !BYOKKeychain.hasKey(for: provider) { return .keyRequired }
            if model.isEmpty { return .modelRequired }
            return .ready
        }
    }

    private func statusTitle(for readiness: ProviderReadinessState) -> String {
        switch readiness {
        case .failed(let message):
            return message == "Checking" ? "Checking" : readiness.title
        default:
            return readiness.title
        }
    }

    private func tone(for readiness: ProviderReadinessState) -> SettingsStatusTone {
        switch readiness {
        case .ready: .success
        case .missing, .needsLogin, .keyRequired, .modelRequired: .warning
        case .disabled: .neutral
        case .failed: .warning
        }
    }

    private func providerSubtitle(_ provider: AssistantProvider) -> String {
        switch provider.category {
        case .cli:
            switch provider {
            case .codex: return "codex"
            case .claude: return "claude"
            case .cursor: return "cursor-agent"
            case .opencode: return "opencode"
            case .antigravity: return "agy"
            default: return provider.rawValue
            }
        case .local:
            if provider == .ollama { return "localhost:11434" }
            if provider == .lmStudio { return "localhost:1234" }
            return "On-device when available"
        case .byok:
            return BYOKKeychain.hasKey(for: provider) ? "Keychain connected" : "Keychain"
        }
    }

    private func health(for provider: AssistantProvider) -> ProviderHealth? {
        viewModel.providerHealth.first(where: { $0.provider == provider })
    }

    private func resetProviderDefaults() {
        settings.provider = .auto
        settings.providerRouteOrder = AssistantProvider.defaultRouteOrder
        settings.disabledProviders = []
        settings.codexModel = .configured
        settings.codexEffort = .xhigh
        settings.claudeModel = .sonnet
        settings.claudeEffort = .medium
        settings.openAIModel = AssistantProvider.openAI.defaultModel
        settings.anthropicModel = AssistantProvider.anthropic.defaultModel
        settings.geminiModel = AssistantProvider.gemini.defaultModel
        settings.openRouterModel = AssistantProvider.openRouter.defaultModel
        settings.groqModel = AssistantProvider.groq.defaultModel
        settings.ollamaModel = AssistantProvider.ollama.defaultModel
        settings.lmStudioModel = AssistantProvider.lmStudio.defaultModel
        for provider in AssistantProvider.allCases {
            settings.setProviderModelID(provider.defaultModel, for: provider)
        }
    }

    private func promptForAPIKey(_ provider: AssistantProvider) {
        let alert = NSAlert()
        alert.messageText = "Connect \(provider.title)"
        alert.informativeText = "Paste your API key. HoverAsk stores it only in macOS Keychain under \(BYOKKeychain.service)."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 360, height: 24))
        field.placeholderString = "\(provider.title) API key"
        alert.accessoryView = field
        if alert.runModal() == .alertFirstButtonReturn {
            viewModel.saveBYOKKey(field.stringValue, for: provider)
        }
    }

    private func confirmDeleteKey(_ provider: AssistantProvider) {
        let alert = NSAlert()
        alert.messageText = "Delete \(provider.title) key?"
        alert.informativeText = "The API key will be removed from macOS Keychain."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            viewModel.deleteBYOKKey(for: provider)
        }
    }

    private func modelBinding(for provider: AssistantProvider) -> Binding<String> {
        modelIDBinding(for: provider)
    }

    private func modelIDBinding(for provider: AssistantProvider) -> Binding<String> {
        Binding(
            get: { settings.providerModelChoice(for: provider).modelID },
            set: { settings.setProviderModelID($0, for: provider) }
        )
    }

    private func choiceBinding(for provider: AssistantProvider) -> Binding<String> {
        Binding(
            get: { settings.providerModelChoice(for: provider).id },
            set: { id in
                guard let choice = modelChoices(for: provider).first(where: { $0.id == id }) else {
                    return
                }
                settings.setProviderModelChoice(choice, for: provider)
            }
        )
    }

    private func modelChoices(for provider: AssistantProvider) -> [ProviderModelChoice] {
        switch provider {
        case .codex:
            return CodexModel.allCases.flatMap { model in
                CodexReasoningEffort.allCases.map { effort in
                    ProviderModelChoice(provider: provider, modelID: model.title, effort: ProviderEffort(codex: effort), displayTitle: "\(model.title) · \(effort.title)")
                }
            }
        case .claude:
            return ClaudeModel.allCases.flatMap { model in
                ClaudeReasoningEffort.allCases.map { effort in
                    ProviderModelChoice(provider: provider, modelID: model.title, effort: ProviderEffort(claude: effort), displayTitle: "\(model.title) · \(effort.title)")
                }
            }
        case .openAI:
            let models = providerModelIDs(for: provider)
            return models.flatMap { model in
                [ProviderEffort.low, .medium, .high].map { effort in
                    ProviderModelChoice(provider: provider, modelID: model, effort: effort, displayTitle: "\(shortModel(model)) · \(effort.title)")
                }
            }
        case .cursor, .opencode, .antigravity, .appleIntelligence:
            return [settings.providerModelChoice(for: provider)]
        case .ollama, .lmStudio, .anthropic, .gemini, .openRouter, .groq:
            return providerModelIDs(for: provider).map { model in
                ProviderModelChoice(provider: provider, modelID: model, effort: .default, displayTitle: shortModel(model))
            }
        }
    }

    private func providerModelIDs(for provider: AssistantProvider) -> [String] {
        var models = viewModel.providerModelOptions[provider] ?? []
        if models.isEmpty {
            models = curatedFallbackModels(for: provider)
        }
        let selected = settings.providerModelChoice(for: provider).modelID
        if !selected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !models.contains(selected) {
            models.insert(selected, at: 0)
        }
        if models.isEmpty {
            models = [provider.defaultModel]
        }
        return Array(NSOrderedSet(array: models).compactMap { $0 as? String })
    }

    private func curatedFallbackModels(for provider: AssistantProvider) -> [String] {
        switch provider {
        case .openAI:
            return ["gpt-4.1-mini", "gpt-4.1", "gpt-4o-mini", "o4-mini"]
        case .anthropic:
            return ["claude-sonnet-4-20250514", "claude-3-7-sonnet-latest", "claude-3-5-haiku-latest"]
        case .gemini:
            return ["gemini-2.5-flash", "gemini-2.5-pro", "gemini-1.5-flash"]
        case .openRouter:
            return ["openai/gpt-4.1-mini", "anthropic/claude-sonnet-4", "google/gemini-2.5-flash"]
        case .groq:
            return ["llama-3.3-70b-versatile", "meta-llama/llama-4-scout-17b-16e-instruct", "qwen/qwen3-32b"]
        default:
            return []
        }
    }

    private func shortModel(_ model: String) -> String {
        model.count > 24 ? "\(model.prefix(21))..." : model
    }

    private var providerPrivacyFooter: some View {
        HStack(spacing: 10) {
            SettingsGlyph(systemName: "shield.checkerboard", tone: .info)
            Text("No screenshots")
            Text("·")
                .foregroundStyle(.white.opacity(0.28))
            Text("Keys use Keychain")
            Text("·")
                .foregroundStyle(.white.opacity(0.28))
            Text("Local providers stay on this Mac")
            Spacer()
            SettingsActionButton("Privacy by design", systemName: "lock") {
                if let url = LegalConfig.privacyURL {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(.white.opacity(0.70))
        .padding(12)
        .background(.white.opacity(0.040), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(.white.opacity(0.09), lineWidth: 1))
    }

    private func openDocs(_ provider: AssistantProvider) {
        if let url = docsURL(for: provider) {
            NSWorkspace.shared.open(url)
        }
    }
}

struct ChatHistorySettingsPage: View {
    @ObservedObject var viewModel: OrbViewModel
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var history: HistoryStore
    @Binding var visibleHistoryCount: Int
    @State private var copiedHistoryToken: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                SettingsPageHeader(title: "Chat History", subtitle: "Saved local conversations on this Mac.")
                Spacer()
                historyToolbar
            }
            SettingsGroup(title: nil) {
                if history.items.isEmpty {
                    emptyHistoryView
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(history.items.prefix(visibleHistoryCount))) { item in
                            savedConversation(item)
                            SettingsDivider()
                                .padding(.vertical, 10)
                        }
                    }
                }

                HStack {
                    Label("History is local-only. API keys are never exported.", systemImage: "info.circle")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.58))
                    Spacer()
                    if visibleHistoryCount < history.items.count {
                        SettingsActionButton("Load more", systemName: "chevron.down") {
                            visibleHistoryCount = min(visibleHistoryCount + 10, history.items.count)
                        }
                    }
                }
            }
        }
    }

    private var historyToolbar: some View {
        HStack(spacing: 10) {
            HistorySaveToggle(isOn: $settings.historyEnabled)
            Text("\(history.items.count) saved · \(formattedHistorySize)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .padding(.trailing, 4)
            SettingsActionButton("Export Markdown", systemName: "square.and.arrow.up", isDisabled: history.items.isEmpty) {
                exportHistory(format: .markdown)
            }
            SettingsActionButton("Export JSON", systemName: "curlybraces", isDisabled: history.items.isEmpty) {
                exportHistory(format: .json)
            }
            SettingsActionButton("Clear history", systemName: "trash", isDisabled: history.items.isEmpty) {
                viewModel.clearHistory()
                visibleHistoryCount = 5
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))
    }

    private var emptyHistoryView: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.cyan.opacity(0.75))
            Text("No saved conversations yet.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            Text("Ask HoverAsk with local history enabled to save prompts and answers here.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.54))
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }

    private func savedConversation(_ item: HistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                Text(historyDateFormatter.string(from: item.createdAt))
                SettingsSmallBadge(item.provider.title)
                Spacer()
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.62))

            let questionToken = "\(item.id.uuidString)-question"
            let answerToken = "\(item.id.uuidString)-answer"

            HistoryBubble(text: item.prompt, side: .user, isCopied: copiedHistoryToken == questionToken) {
                copyToPasteboard(item.prompt, token: questionToken)
            }
            HistoryBubble(text: item.answer, side: .assistant, isCopied: copiedHistoryToken == answerToken) {
                copyToPasteboard(item.answer, token: answerToken)
            }
        }
        .padding(.vertical, 4)
    }

    private var historyDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy, h:mm a"
        return formatter
    }

    private enum ExportFormat {
        case markdown
        case json
    }

    private func exportHistory(format: ExportFormat) {
        let panel = NSSavePanel()
        switch format {
        case .markdown:
            if let markdownType = UTType(filenameExtension: "md") {
                panel.allowedContentTypes = [markdownType]
            }
            panel.nameFieldStringValue = "HoverAsk Chat History.md"
        case .json:
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "HoverAsk Chat History.json"
        }
        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }
        do {
            switch format {
            case .markdown:
                try history.exportMarkdown(to: url)
            case .json:
                try history.exportJSON(to: url)
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    private func copyToPasteboard(_ text: String, token: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(trimmed, forType: .string)
        withAnimation(.easeOut(duration: 0.12)) {
            copiedHistoryToken = token
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if copiedHistoryToken == token {
                withAnimation(.easeIn(duration: 0.14)) {
                    copiedHistoryToken = nil
                }
            }
        }
    }
}

private struct HistorySaveToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(trackFill)
                        .overlay(Capsule().stroke(trackStroke, lineWidth: 1))
                    Circle()
                        .fill(thumbFill)
                        .frame(width: 12, height: 12)
                        .padding(3)
                }
                .frame(width: 32, height: 18)
                Text("Save chat history")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(isOn ? Color.orange.opacity(0.96) : Color.white.opacity(0.58))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isOn ? Color.orange.opacity(0.10) : Color.white.opacity(0.045), in: Capsule())
            .overlay(Capsule().stroke(isOn ? Color.orange.opacity(0.30) : Color.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Save chat history")
        .accessibilityValue(isOn ? "On" : "Off")
    }

    private var trackFill: Color {
        isOn ? Color.orange.opacity(0.32) : Color.white.opacity(0.09)
    }

    private var trackStroke: Color {
        isOn ? Color.orange.opacity(0.52) : Color.white.opacity(0.14)
    }

    private var thumbFill: Color {
        isOn ? Color.orange.opacity(0.96) : Color.white.opacity(0.46)
    }
}

private enum HistoryBubbleSide {
    case user
    case assistant
}

private struct HistoryBubble: View {
    let text: String
    let side: HistoryBubbleSide
    var isCopied = false
    let copyAction: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            if side == .user {
                Spacer(minLength: 190)
            } else {
                AvatarVisual(style: .orb, size: 34, phase: .idle, motion: .idle)
                    .padding(.top, 4)
            }

            HStack(alignment: .top, spacing: 8) {
                Text(text)
                    .font(.system(size: 13, weight: side == .user ? .medium : .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(side == .user ? 0.90 : 0.78))
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                MiniIconButton(systemName: "doc.on.doc", label: side == .user ? "Copy question" : "Copy answer") {
                    copyAction()
                }
                .overlay(alignment: side == .user ? .topTrailing : .topLeading) {
                    if isCopied {
                        CopyFeedbackPill()
                            .offset(x: side == .user ? 2 : -2, y: -26)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: 560, alignment: side == .user ? .trailing : .leading)
            .background(background, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(stroke, lineWidth: 1))

            if side == .assistant {
                Spacer(minLength: 190)
            }
        }
    }

    private var background: LinearGradient {
        switch side {
        case .user:
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.42, blue: 0.43).opacity(0.54),
                    Color(red: 0.04, green: 0.19, blue: 0.21).opacity(0.76)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .assistant:
            LinearGradient(
                colors: [
                    Color.white.opacity(0.080),
                    Color(red: 0.02, green: 0.15, blue: 0.16).opacity(0.64)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var stroke: Color {
        side == .user ? .cyan.opacity(0.18) : .white.opacity(0.12)
    }
}

struct AdvancedSettingsPage: View {
    @ObservedObject var viewModel: OrbViewModel
    @EnvironmentObject private var settings: SettingsStore
    @State private var isRecordingHotKey = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsPageHeader(title: "Advanced", subtitle: "Keyboard control and reset options.")
            SettingsGroup(title: "Keyboard shortcut") {
                HStack(spacing: 12) {
                    SettingsGlyph(systemName: "keyboard", tone: .info)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wake HoverAsk")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Text(viewModel.hotKeyRegistrationMessage.isEmpty ? "Global shortcut for opening HoverAsk." : viewModel.hotKeyRegistrationMessage)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.50))
                    }
                    Spacer()
                    HotKeyRecorderButton(shortcut: $settings.hotKeyShortcut, isRecording: $isRecordingHotKey)
                    SettingsActionButton("Default") {
                        settings.hotKeyShortcut = .default
                    }
                }
            }
            SettingsGroup(title: "Reset") {
                Text("Restore HoverAsk settings to defaults. Local chat history and Keychain API keys are not cleared.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))
                SettingsActionButton("Reset settings", systemName: "arrow.counterclockwise") {
                    confirmReset(settings: settings)
                }
            }
        }
    }
}

struct SettingsPageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
            Text(subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
        }
    }
}

struct SettingsGroup<Content: View>: View {
    var title: String?
    @ViewBuilder let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
            }
            content
        }
        .padding(14)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))
    }
}

struct SettingsBucket<Content: View>: View {
    let title: String
    let status: String
    let tone: SettingsStatusTone
    let detail: String
    @ViewBuilder let content: Content

    var body: some View {
        SettingsGroup(title: nil) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Circle()
                    .fill(tone.color)
                    .frame(width: 8, height: 8)
                Text(status)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(tone.color)
                Spacer()
            }
            Text(detail)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
            VStack(spacing: 0) {
                content
            }
            .background(.white.opacity(0.026), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.white.opacity(0.07), lineWidth: 1))
        }
    }
}

struct SettingsProviderRow: View {
    let icon: String
    let title: String
    let detail: String
    let badge: String
    let status: String
    let statusTone: SettingsStatusTone
    let model: String
    let actionTitle: String
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.76))
                .frame(width: 28, height: 28)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            Circle()
                .fill(statusTone.color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .frame(width: 118, alignment: .leading)
            Text(detail)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.52))
                .frame(width: 92, alignment: .leading)
            SettingsSmallBadge(badge)
            Text(status)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(statusTone.color.opacity(0.94))
                .frame(width: 96, alignment: .leading)
            if !model.isEmpty {
                Text("Model")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
                SettingsPill(model, systemName: "chevron.down")
                    .frame(width: 130, alignment: .leading)
            } else {
                Spacer(minLength: 140)
            }
            SettingsActionButton(actionTitle, isDisabled: isDisabled, action: action)
            MiniIconButton(systemName: "ellipsis", label: "More", isDisabled: isDisabled) {}
        }
        .padding(.horizontal, 10)
        .frame(height: 45)
        SettingsDivider()
            .padding(.leading, 50)
    }
}

struct SettingsDisclosureFooter: View {
    let title: String
    let trailing: String

    init(_ title: String, trailing: String) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(trailing)
                .foregroundStyle(.cyan.opacity(0.82))
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(.white.opacity(0.58))
        .padding(.horizontal, 10)
        .frame(height: 34)
    }
}

struct SettingsStatusRow: View {
    let icon: String
    let title: String
    let detail: String
    let status: String
    let tone: SettingsStatusTone
    var actionSystemName: String?
    var actionLabel = "Open"
    var actionDisabled = false
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            SettingsGlyph(systemName: icon, tone: tone)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.50))
            }
            Spacer()
            HStack(spacing: 8) {
                Circle()
                    .fill(tone.color)
                    .frame(width: 8, height: 8)
                Text(status)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
            }
            if let actionSystemName, let action {
                MiniIconButton(systemName: actionSystemName, label: actionLabel, isDisabled: actionDisabled, action: action)
            }
        }
        .frame(minHeight: 48)
        SettingsDivider()
    }
}

struct SettingsPickerRow<Selection: Hashable, Content: View>: View {
    let title: String
    let detail: String
    @Binding var selection: Selection
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.50))
            }
            Spacer()
            Picker(title, selection: $selection) {
                content
            }
            .labelsHidden()
            .frame(width: 230)
        }
        .frame(minHeight: 46)
        SettingsDivider()
    }
}

struct SettingsInlinePicker<Selection: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: Selection
    @ViewBuilder let content: Content

    init(_ title: String, selection: Binding<Selection>, @ViewBuilder content: () -> Content) {
        self.title = title
        _selection = selection
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.48))
            Picker(title, selection: $selection) {
                content
            }
            .labelsHidden()
            .frame(width: 180)
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.50))
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .frame(minHeight: 46)
        SettingsDivider()
    }
}

struct SettingsActionButton: View {
    let title: String
    var systemName: String?
    var isDisabled = false
    let action: () -> Void

    init(_ title: String, systemName: String? = nil, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemName = systemName
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let systemName {
                    Image(systemName: systemName)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(.white.opacity(isDisabled ? 0.44 : 0.88))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.white.opacity(isDisabled ? 0.045 : 0.075), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(.white.opacity(isDisabled ? 0.07 : 0.13), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

struct HotKeyRecorderButton: View {
    @Binding var shortcut: HotKeyShortcut
    @Binding var isRecording: Bool

    var body: some View {
        Button {
            isRecording = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isRecording ? "record.circle" : "keyboard")
                Text(isRecording ? "Press shortcut..." : shortcut.displayText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.88))
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(.cyan.opacity(isRecording ? 0.16 : 0.08), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(.cyan.opacity(isRecording ? 0.32 : 0.16), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .background(
            Group {
                if isRecording {
                    HotKeyCaptureView { captured in
                        shortcut = captured
                        isRecording = false
                    }
                    .frame(width: 0, height: 0)
                }
            }
        )
    }
}

struct HotKeyCaptureView: NSViewRepresentable {
    let onCapture: (HotKeyShortcut) -> Void

    func makeNSView(context: Context) -> CaptureView {
        let view = CaptureView()
        view.onCapture = onCapture
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: CaptureView, context: Context) {
        nsView.onCapture = onCapture
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }

    final class CaptureView: NSView {
        var onCapture: ((HotKeyShortcut) -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            var modifiers: UInt32 = 0
            if event.modifierFlags.contains(.command) { modifiers |= UInt32(cmdKey) }
            if event.modifierFlags.contains(.shift) { modifiers |= UInt32(shiftKey) }
            if event.modifierFlags.contains(.option) { modifiers |= UInt32(optionKey) }
            if event.modifierFlags.contains(.control) { modifiers |= UInt32(controlKey) }
            if modifiers == 0 {
                NSSound.beep()
                return
            }
            onCapture?(HotKeyShortcut(keyCode: UInt32(event.keyCode), modifiers: modifiers))
        }
    }
}

struct SettingsBottomAction: View {
    let systemName: String
    let title: String
    var isDisabled = false
    var isProminent = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemName)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .opacity(0.8)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, isProminent ? 9 : 0)
            .frame(height: 30)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isProminent ? Color.orange.opacity(isDisabled ? 0.055 : 0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isProminent ? Color.orange.opacity(isDisabled ? 0.10 : 0.26) : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private var foreground: Color {
        if isProminent {
            return Color.orange.opacity(isDisabled ? 0.46 : 0.95)
        }
        return Color.white.opacity(isDisabled ? 0.36 : 0.72)
    }
}

struct SettingsSmallBadge: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.cyan.opacity(0.86))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.cyan.opacity(0.10), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(.cyan.opacity(0.24), lineWidth: 1))
    }
}

struct SettingsPill: View {
    let title: String
    let systemName: String?

    init(_ title: String, systemName: String? = nil) {
        self.title = title
        self.systemName = systemName
    }

    var body: some View {
        HStack(spacing: 7) {
            Text(title)
                .lineLimit(1)
            if let systemName {
                Image(systemName: systemName)
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundStyle(.white.opacity(0.82))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

struct SettingsGlyph: View {
    let systemName: String
    let tone: SettingsStatusTone

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(.white.opacity(0.72))
            .frame(width: 30, height: 30)
            .background(tone.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(tone.color.opacity(0.18), lineWidth: 1))
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.07))
            .frame(height: 1)
    }
}

struct AvatarPreview: View {
    let style: AvatarStyle
    let selected: Bool
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                AvatarVisual(style: style, size: 74, phase: .idle, motion: .idle)
                Text(style.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(12)
            .frame(width: 124)
            .background(.white.opacity(selected ? 0.08 : 0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(selected ? .cyan.opacity(0.35) : .white.opacity(0.08), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct SettingsWindowBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.015, green: 0.052, blue: 0.062)
            LinearGradient(
                colors: [
                    Color.cyan.opacity(0.10),
                    Color(red: 0.02, green: 0.15, blue: 0.17).opacity(0.88),
                    Color.black.opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

enum SettingsStatusTone {
    case success
    case warning
    case info
    case neutral

    var color: Color {
        switch self {
        case .success: Color.green.opacity(0.88)
        case .warning: Color.orange.opacity(0.86)
        case .info: Color.cyan.opacity(0.86)
        case .neutral: Color.white.opacity(0.44)
        }
    }
}

private var appVersion: String {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.0"
    return "v\(version)"
}

private var formattedHistorySize: String {
    let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("HoverAsk", isDirectory: true)
    let url = directory.appendingPathComponent("history.json")
    let bytes = Double((try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0)
    if bytes < 1024 {
        return "\(Int(bytes)) B"
    }
    if bytes < 1024 * 1024 {
        return "\(Int((bytes / 1024).rounded())) KB"
    }
    return String(format: "%.1f MB", bytes / 1024 / 1024)
}

private func relativeRefreshText(_ date: Date?) -> String {
    guard let date else {
        return "not refreshed yet"
    }
    let seconds = max(0, Int(Date().timeIntervalSince(date)))
    if seconds < 5 {
        return "refreshed just now"
    }
    if seconds < 60 {
        return "refreshed \(seconds)s ago"
    }
    let minutes = seconds / 60
    if minutes < 60 {
        return "refreshed \(minutes)m ago"
    }
    let hours = minutes / 60
    return "refreshed \(hours)h ago"
}

private func openURL(_ string: String) {
    guard let url = URL(string: string) else {
        return
    }
    NSWorkspace.shared.open(url)
}

private func showAbout() {
    let alert = NSAlert()
    alert.messageText = "HoverAsk"
    alert.informativeText = "A native macOS floating voice assistant.\nVersion \(appVersion)"
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

@MainActor
private func confirmReset(settings: SettingsStore) {
    let alert = NSAlert()
    alert.messageText = "Reset settings?"
    alert.informativeText = "This will restore HoverAsk settings to their defaults. Local history is not cleared."
    alert.addButton(withTitle: "Reset")
    alert.addButton(withTitle: "Cancel")
    if alert.runModal() == .alertFirstButtonReturn {
        settings.resetToDefaults()
    }
}

private func providerIcon(_ provider: AssistantProvider) -> String {
    switch provider {
    case .codex: "terminal"
    case .claude: "textformat"
    case .cursor: "cube"
    case .opencode: "curlybraces.square"
    case .antigravity: "sparkles"
    case .appleIntelligence: "apple.logo"
    case .ollama: "server.rack"
    case .lmStudio: "shippingbox"
    case .openAI: "swirl.circle.righthalf.filled"
    case .anthropic: "textformat"
    case .gemini: "sparkle"
    case .openRouter: "point.3.connected.trianglepath.dotted"
    case .groq: "bolt"
    }
}

private func localIcon(_ provider: LocalProviderKind) -> String {
    switch provider {
    case .appleIntelligence: "apple.logo"
    case .ollama: "server.rack"
    case .lmStudio: "shippingbox"
    }
}

private func byokIcon(_ provider: String) -> String {
    switch provider {
    case "OpenAI": "swirl.circle.righthalf.filled"
    case "Anthropic": "textformat"
    case "Gemini": "sparkle"
    default: "key"
    }
}

private func docsURL(for provider: AssistantProvider) -> URL? {
    switch provider {
    case .codex:
        URL(string: "https://developers.openai.com/codex/")
    case .claude:
        URL(string: "https://code.claude.com/docs/en/overview")
    case .cursor:
        URL(string: "https://cursor.com/cli")
    case .opencode:
        URL(string: "https://opencode.ai/docs/cli/")
    case .antigravity:
        URL(string: "https://antigravity.google/docs/cli-using")
    case .appleIntelligence:
        URL(string: "https://developer.apple.com/apple-intelligence/")
    case .ollama:
        URL(string: "https://ollama.com/download")
    case .lmStudio:
        URL(string: "https://lmstudio.ai/")
    case .openAI:
        URL(string: "https://platform.openai.com/api-keys")
    case .anthropic:
        URL(string: "https://console.anthropic.com/settings/keys")
    case .gemini:
        URL(string: "https://aistudio.google.com/app/apikey")
    case .openRouter:
        URL(string: "https://openrouter.ai/keys")
    case .groq:
        URL(string: "https://console.groq.com/keys")
    }
}
