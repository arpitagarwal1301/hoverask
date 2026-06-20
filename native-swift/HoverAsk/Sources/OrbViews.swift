import AppKit
import SwiftUI

struct OrbRootView: View {
    @ObservedObject var viewModel: OrbViewModel
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        ZStack {
            Color.clear

            switch viewModel.phase {
            case .idle:
                IdleOrbView(viewModel: viewModel)
            case .listening:
                CompanionChatView(viewModel: viewModel, title: "Listening", bodyText: liveTranscript, mode: .listening)
            case .thinking:
                CompanionChatView(viewModel: viewModel, title: providerThinkingTitle, bodyText: viewModel.transcript, mode: .thinking)
            case .answer:
                CompanionChatView(viewModel: viewModel, title: answerTitle, bodyText: viewModel.answer, mode: .answer)
            case .error(let message):
                CompanionChatView(viewModel: viewModel, title: "Needs attention", bodyText: message, mode: .error)
            case .settings:
                SettingsPanel(viewModel: viewModel)
            }
        }
        .frame(minWidth: 1, maxWidth: .infinity, minHeight: 1, maxHeight: .infinity)
        .background(Color.clear)
    }

    private var liveTranscript: String {
        viewModel.transcript.isEmpty ? "Speak now..." : viewModel.transcript
    }

    private var providerThinkingTitle: String {
        if let provider = viewModel.activeProvider {
            return "\(provider.title) is thinking"
        }
        return "Thinking"
    }

    private var answerTitle: String {
        if let provider = viewModel.activeProvider {
            return "\(provider.title) answered"
        }
        return "Answered"
    }
}

struct IdleOrbView: View {
    @ObservedObject var viewModel: OrbViewModel
    @EnvironmentObject private var settings: SettingsStore
    @State private var isHovering = false

    var body: some View {
        ZStack {
            AvatarVisual(style: settings.avatarStyle, size: 104, phase: viewModel.phase, motion: viewModel.companionVisualMotion)
                .overlay(
                    ClickDragOverlay(
                        onClick: { viewModel.primaryOrbAction() },
                        onHoldStart: { viewModel.holdBegan() },
                        onHoldEnd: { viewModel.holdEnded() },
                        onDragStart: { viewModel.dragStarted() },
                        onDragEnd: { viewModel.dragEnded() }
                    )
                )

            VStack {
                HStack {
                    Spacer()
                    IconCircle(systemName: "gearshape.fill", label: "Settings") {
                        viewModel.openSettings()
                    }
                    .opacity(isHovering ? 0.92 : 0.04)
                    .allowsHitTesting(isHovering)
                }
                Spacer()
                HStack {
                    Spacer()
                    IconCircle(systemName: "xmark", label: "Hide") {
                        viewModel.dismissOrb()
                    }
                    .opacity(isHovering ? 0.82 : 0.0)
                    .allowsHitTesting(isHovering)
                }
            }
            .padding(14)
        }
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .animation(.easeInOut(duration: 0.16), value: isHovering)
    }
}

enum CompanionBubbleMode {
    case listening
    case thinking
    case answer
    case error
}

struct CompanionChatView: View {
    @ObservedObject var viewModel: OrbViewModel
    @EnvironmentObject private var settings: SettingsStore
    let title: String
    let bodyText: String
    let mode: CompanionBubbleMode
    @State private var metrics: WindowMetrics?

    var body: some View {
        ZStack {
            Color.clear
            companionLayout
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WindowMetricsReader(metrics: $metrics))
    }

    @ViewBuilder
    private var companionLayout: some View {
        switch settings.bubblePlacement {
        case .above:
            VStack(spacing: 2) {
                bubble
                BubbleTail(direction: .down, tone: mode)
                avatar
            }
            .padding(.top, 28)
        case .side:
            if shouldFlipSide {
                HStack(spacing: 2) {
                    bubble
                    BubbleTail(direction: .right, tone: mode)
                    avatar
                }
            } else {
                HStack(spacing: 2) {
                    avatar
                    BubbleTail(direction: .left, tone: mode)
                    bubble
                }
            }
        case .bottom:
            VStack(spacing: 2) {
                avatar
                BubbleTail(direction: .up, tone: mode)
                bubble
            }
            .padding(.bottom, 28)
        }
    }

    private var avatar: some View {
        AvatarVisual(style: settings.avatarStyle, size: 112, phase: viewModel.phase, motion: .idle)
            .overlay(
                ClickDragOverlay(
                    onClick: { viewModel.primaryOrbAction() },
                    onHoldStart: { viewModel.holdBegan() },
                    onHoldEnd: { viewModel.holdEnded() },
                    onDragStart: { viewModel.dragStarted() },
                    onDragEnd: { viewModel.dragEnded() }
                )
            )
    }

    private var bubble: some View {
        CompanionBubbleView(viewModel: viewModel, title: title, bodyText: bodyText, mode: mode)
            .frame(maxWidth: settings.bubblePlacement == .side ? 430 : 500)
    }

    private var shouldFlipSide: Bool {
        guard let metrics else {
            return false
        }
        return metrics.windowFrame.midX > metrics.visibleFrame.midX
    }
}

struct CompanionBubbleView: View {
    @ObservedObject var viewModel: OrbViewModel
    let title: String
    let bodyText: String
    let mode: CompanionBubbleMode

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: statusIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isError ? .pink : .cyan)
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
                Spacer(minLength: 10)
                controls
            }

            if mode == .listening {
                ListeningWaveformStrip()
            } else if mode == .thinking {
                ThinkingBars()
            }

            Text(displayText)
                .font(.system(size: textSize, weight: isError ? .medium : .regular, design: .rounded))
                .foregroundStyle(isError ? Color(red: 1, green: 0.82, blue: 0.82) : Color.white.opacity(0.94))
                .lineLimit(mode == .answer ? 8 : 5)
                .fixedSize(horizontal: false, vertical: true)
                .background(PanelDragSurface())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.black.opacity(0.62))
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .cyan.opacity(isError ? 0.06 : 0.13),
                                .indigo.opacity(0.12),
                                .pink.opacity(isError ? 0.14 : 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(isError ? 0.24 : 0.18), lineWidth: 1)
            }
        )
        .shadow(color: (isError ? Color.pink : Color.cyan).opacity(0.14), radius: 22, y: 8)
    }

    @ViewBuilder
    private var controls: some View {
        HStack(spacing: 7) {
            if mode == .listening {
                Button {
                    viewModel.stopListeningAndSend()
                } label: {
                    Label("Send", systemImage: "paperplane.fill")
                }
                .buttonStyle(GlassButtonStyle())
            } else if mode == .answer || mode == .error {
                IconCircle(systemName: "doc.on.doc", label: "Copy") {
                    copyToPasteboard(bodyText)
                }
                IconCircle(systemName: "arrow.clockwise", label: "Retry") {
                    viewModel.retryLastTranscript()
                }
            }

            IconCircle(systemName: "gearshape.fill", label: "Settings") {
                viewModel.openSettings()
            }
            IconCircle(systemName: "xmark", label: "Collapse") {
                viewModel.collapse()
            }
        }
    }

    private var displayText: String {
        let trimmed = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            switch mode {
            case .listening: return "Speak now..."
            case .thinking: return "Working on it..."
            case .answer: return "I do not have an answer yet."
            case .error: return "Something needs attention."
            }
        }
        return trimmed
    }

    private var statusIcon: String {
        switch mode {
        case .listening: return "waveform"
        case .thinking: return "sparkles"
        case .answer: return "quote.bubble.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private var isError: Bool {
        mode == .error
    }

    private var textSize: CGFloat {
        switch mode {
        case .listening: 18
        case .thinking: 16
        case .answer: 16
        case .error: 14
        }
    }

    private func copyToPasteboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

enum BubbleTailDirection {
    case up
    case down
    case left
    case right
}

struct BubbleTail: View {
    let direction: BubbleTailDirection
    let tone: CompanionBubbleMode

    var body: some View {
        Triangle()
            .fill(fillColor)
            .frame(width: tailSize.width, height: tailSize.height)
            .rotationEffect(rotation)
            .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
    }

    private var fillColor: Color {
        tone == .error ? .pink.opacity(0.22) : .cyan.opacity(0.18)
    }

    private var tailSize: CGSize {
        switch direction {
        case .up, .down: CGSize(width: 24, height: 15)
        case .left, .right: CGSize(width: 15, height: 24)
        }
    }

    private var rotation: Angle {
        switch direction {
        case .up: .degrees(0)
        case .down: .degrees(180)
        case .left: .degrees(-90)
        case .right: .degrees(90)
        }
    }
}

struct WindowMetrics: Equatable {
    let windowFrame: CGRect
    let visibleFrame: CGRect
}

struct WindowMetricsReader: NSViewRepresentable {
    @Binding var metrics: WindowMetrics?

    func makeCoordinator() -> Coordinator {
        Coordinator(metrics: $metrics)
    }

    func makeNSView(context: Context) -> WindowMetricsNSView {
        let view = WindowMetricsNSView()
        view.onUpdate = { metrics in
            context.coordinator.metrics.wrappedValue = metrics
        }
        return view
    }

    func updateNSView(_ nsView: WindowMetricsNSView, context: Context) {
        nsView.onUpdate = { metrics in
            context.coordinator.metrics.wrappedValue = metrics
        }
        nsView.publish()
    }

    final class Coordinator {
        var metrics: Binding<WindowMetrics?>

        init(metrics: Binding<WindowMetrics?>) {
            self.metrics = metrics
        }
    }
}

final class WindowMetricsNSView: NSView {
    var onUpdate: ((WindowMetrics) -> Void)?
    private var timer: Timer?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        timer?.invalidate()
        if window != nil {
            timer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { [weak self] _ in
                self?.publish()
            }
            publish()
        }
    }

    deinit {
        timer?.invalidate()
    }

    func publish() {
        guard let window, let screen = window.screen else {
            return
        }
        onUpdate?(WindowMetrics(windowFrame: window.frame, visibleFrame: screen.visibleFrame))
    }
}

struct SettingsPanel: View {
    @ObservedObject var viewModel: OrbViewModel
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var history: HistoryStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Settings")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                IconCircle(systemName: "arrow.clockwise", label: "Refresh status") {
                    viewModel.refreshHealth()
                }
                IconCircle(systemName: "xmark", label: "Close") {
                    viewModel.closeSettings()
                }
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    assistantGroup
                    providerStatusGroup
                    providerModelGroup
                    historyGroup
                }
                .padding(.bottom, 2)
            }
        }
        .padding(20)
        .background(PanelBackground())
    }

    private var assistantGroup: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Provider", selection: $settings.provider) {
                    ForEach(ProviderSelection.allCases) { provider in
                        Text(provider.title).tag(provider)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Assistant", selection: $settings.avatarStyle) {
                    ForEach(AvatarStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }

                Picker("Chat bubble", selection: $settings.bubblePlacement) {
                    ForEach(BubblePlacement.allCases) { placement in
                        Text(placement.title).tag(placement)
                    }
                }

                Picker("Companion movement", selection: $settings.companionMovementMode) {
                    ForEach(CompanionMovementMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }

                Picker("Speech input", selection: $settings.voiceLocale) {
                    ForEach(VoiceLocale.allCases) { locale in
                        Text(locale.title).tag(locale)
                    }
                }

                Picker("Reply voice", selection: $settings.speechVoice) {
                    ForEach(SpeechVoicePreset.allCases) { voice in
                        Text(voice.title).tag(voice)
                    }
                }

                HStack {
                    Text("Voice pace")
                    Slider(value: $settings.speechRate, in: 0.34...0.58)
                    Button("Preview") {
                        viewModel.previewVoice()
                    }
                    .buttonStyle(GlassButtonStyle())
                }

                Picker("Listen mode", selection: $settings.listenMode) {
                    ForEach(ListenMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }

                Toggle("Keep listening after answers", isOn: $settings.continuousConversationEnabled)
                Toggle("Speak answers aloud", isOn: $settings.spokenRepliesEnabled)
            }
        } label: {
            Text("Assistant")
        }
        .groupBoxStyle(GlassGroupBoxStyle())
    }

    private var providerModelGroup: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Codex model", selection: $settings.codexModel) {
                    ForEach(CodexModel.allCases) { model in
                        Text(model.title).tag(model)
                    }
                }
                Picker("Codex effort", selection: $settings.codexEffort) {
                    ForEach(CodexReasoningEffort.allCases) { effort in
                        Text(effort.title).tag(effort)
                    }
                }
                Text("Codex uses \(settings.codexModel.title) with \(settings.codexEffort.title) effort.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.54))

                Divider().overlay(.white.opacity(0.12))

                Picker("Claude model", selection: $settings.claudeModel) {
                    ForEach(ClaudeModel.allCases) { model in
                        Text(model.title).tag(model)
                    }
                }
                Picker("Claude effort", selection: $settings.claudeEffort) {
                    ForEach(ClaudeReasoningEffort.allCases) { effort in
                        Text(effort.title).tag(effort)
                    }
                }
                Text("Claude uses \(settings.claudeModel.title) with \(settings.claudeEffort.title) effort.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.54))
            }
        } label: {
            Text("Models")
        }
        .groupBoxStyle(GlassGroupBoxStyle())
    }

    private var providerStatusGroup: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.providerHealth) { health in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(health.authenticated ? Color.green : health.installed ? Color.yellow : Color.red)
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(health.provider.title)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                            Text(statusText(health))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.54))
                                .lineLimit(1)
                        }
                        Spacer()
                        if health.installed {
                            Button(health.authenticated ? "Re-login" : "Login") {
                                viewModel.login(provider: health.provider)
                            }
                            .buttonStyle(GlassButtonStyle())
                        }
                    }
                }
            }
        } label: {
            Text("Provider status")
        }
        .groupBoxStyle(GlassGroupBoxStyle())
    }

    private var historyGroup: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Keep local history", isOn: $settings.historyEnabled)
                HStack {
                    Text("\(history.items.count) saved")
                    Spacer()
                    Button("Clear history") {
                        viewModel.clearHistory()
                    }
                    .buttonStyle(GlassButtonStyle())
                    .disabled(history.items.isEmpty)
                }
                ForEach(history.items.prefix(3)) { item in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.prompt)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                        Text(item.answer)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.58))
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }
        } label: {
            Text("Local history")
        }
        .groupBoxStyle(GlassGroupBoxStyle())
    }

    private func statusText(_ health: ProviderHealth) -> String {
        if health.authenticated {
            return "Ready"
        }
        if health.installed {
            return "Needs login"
        }
        return "Missing CLI"
    }
}

struct AvatarVisual: View {
    let style: AvatarStyle
    let size: CGFloat
    let phase: OrbPhase
    let motion: CompanionVisualMotion

    var body: some View {
        switch style {
        case .orb:
            OrbVisual(size: size, phase: phase)
        case .dog:
            GlassMascotVisual(size: size, phase: phase, motion: motion, kind: .dog)
        case .cat:
            GlassMascotVisual(size: size, phase: phase, motion: motion, kind: .cat)
        }
    }
}

enum MascotSpriteState: String {
    case idle
    case listening
    case thinking
    case answer
    case error
    case run

    var framesPerSecond: Double {
        switch self {
        case .idle: 6
        case .listening: 8
        case .thinking: 5
        case .answer: 9
        case .error: 3
        case .run: 12
        }
    }
}

struct GlassMascotVisual: View {
    let size: CGFloat
    let phase: OrbPhase
    let motion: CompanionVisualMotion
    let kind: AnimalAvatarKind
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { timeline in
            let state = spriteState
            let cycle = state == .listening ? 4.8 : 12.0
            let progress = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle) / cycle
            let breathe = reduceMotion ? 0 : sin(progress * .pi * 2)
            let image = BundleImageLoader.mascotFrame(kind: kind, state: state, time: timeline.date.timeIntervalSinceReferenceDate)
                ?? BundleImageLoader.image(named: assetName)

            ZStack {
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.08 + breathe * 0.015),
                                Color(red: 1.0, green: 0.62, blue: 0.20).opacity(0.04)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: size * 0.62, height: size * 0.12)
                    .blur(radius: 10)
                    .offset(y: size * 0.43)

                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .scaleEffect(x: shouldFaceRight ? -1 : 1, y: 1, anchor: .center)
                        .shadow(color: Color.cyan.opacity(0.18 + breathe * 0.05), radius: phase == .listening ? 28 : 18, y: 8)
                        .shadow(color: Color(red: 1.0, green: 0.62, blue: 0.20).opacity(0.10), radius: 22, y: 13)
                        .shadow(color: .black.opacity(0.16), radius: 24, y: 16)
                        .offset(y: reduceMotion || state == .run ? 0 : breathe * 2.6)
                } else {
                    OrbVisual(size: size * 0.78, phase: phase)
                }
            }
            .frame(width: size, height: size)
            .scaleEffect(phase == .listening ? 1.035 : 1.0)
        }
    }

    private var spriteState: MascotSpriteState {
        switch phase {
        case .idle:
            motion.isRunning ? .run : .idle
        case .listening:
            .listening
        case .thinking:
            .thinking
        case .answer:
            .answer
        case .error:
            .error
        case .settings:
            .idle
        }
    }

    private var shouldFaceRight: Bool {
        phase == .idle && motion.facingRight
    }

    private var assetName: String {
        switch kind {
        case .dog: "GlassDog"
        case .cat: "GlassCat"
        }
    }
}

struct ListeningWaveformStrip: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<7, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                .cyan.opacity(0.78),
                                Color(red: 1.0, green: 0.60, blue: 0.22).opacity(index % 3 == 0 ? 0.50 : 0.18)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: CGFloat(10 + (index % 4) * 5))
                    .scaleEffect(y: animate ? CGFloat(0.72 + Double((index * 17) % 9) / 8.0) : CGFloat(0.42 + Double((index * 11) % 7) / 10.0))
                    .animation(
                        .easeInOut(duration: 0.42)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.055),
                        value: animate
                    )
            }
        }
        .frame(height: 30)
        .padding(.horizontal, 11)
        .padding(.vertical, 5)
        .background(.white.opacity(0.075), in: Capsule())
        .overlay(Capsule().stroke(.cyan.opacity(0.18), lineWidth: 1))
        .shadow(color: .cyan.opacity(0.22), radius: 14, y: 4)
        .onAppear { animate = true }
    }
}

@MainActor
enum BundleImageLoader {
    private static var frameCache: [String: [NSImage]] = [:]

    static func image(named name: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }

    static func mascotFrame(kind: AnimalAvatarKind, state: MascotSpriteState, time: TimeInterval) -> NSImage? {
        let frames = mascotFrames(kind: kind, state: state)
        guard !frames.isEmpty else {
            return nil
        }
        let frameIndex = Int((time * state.framesPerSecond).rounded(.down)) % frames.count
        return frames[frameIndex]
    }

    private static func mascotFrames(kind: AnimalAvatarKind, state: MascotSpriteState) -> [NSImage] {
        let key = "\(kind.directoryName)-\(state.rawValue)"
        if let cached = frameCache[key] {
            return cached
        }
        let subdirectory = "MascotFrames/\(kind.directoryName)/\(state.rawValue)"
        let urls = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: subdirectory) ?? []
        let frames = urls
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { NSImage(contentsOf: $0) }
        frameCache[key] = frames
        return frames
    }
}

struct OrbVisual: View {
    let size: CGFloat
    let phase: OrbPhase

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let pulse = phase == .listening ? (sin(time * 4.2) + 1) / 2 : (sin(time * 1.45) + 1) / 2

            ZStack {
                if let image = BundleImageLoader.image(named: "GlassOrb") {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(phase == .listening ? sin(time * 0.9) * 1.2 : sin(time * 0.35) * 0.45))
                        .shadow(color: Color.cyan.opacity(phase == .listening ? 0.50 : 0.30), radius: phase == .listening ? 26 : 18, x: -2, y: 5)
                        .shadow(color: Color(red: 1.0, green: 0.55, blue: 0.16).opacity(0.20), radius: 24, x: 8, y: 10)
                        .shadow(color: .black.opacity(0.22), radius: 22, y: 14)
                } else {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.70, green: 1.0, blue: 0.96),
                                    Color(red: 0.02, green: 0.42, blue: 0.42),
                                    Color(red: 0.02, green: 0.025, blue: 0.03),
                                    Color(red: 0.95, green: 0.45, blue: 0.12).opacity(0.55)
                                ],
                                center: UnitPoint(x: 0.32, y: 0.24),
                                startRadius: 2,
                                endRadius: size * 0.64
                            )
                        )
                        .overlay(Circle().stroke(Color.cyan.opacity(0.58), lineWidth: 1.5))
                        .shadow(color: .cyan.opacity(0.32), radius: 18)
                }

                if phase == .listening {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(Color.cyan.opacity(0.18 - Double(index) * 0.035), lineWidth: 1)
                            .scaleEffect(1.04 + CGFloat(index) * 0.14 + CGFloat(pulse) * 0.10)
                            .blur(radius: CGFloat(index) * 0.7)
                    }
                }
            }
            .frame(width: size, height: size)
            .scaleEffect(phase == .listening ? 1.04 : 1)
        }
    }
}
enum AnimalAvatarKind {
    case dog
    case cat

    var directoryName: String {
        switch self {
        case .dog: "dog"
        case .cat: "cat"
        }
    }
}

struct AnimalAvatarVisual: View {
    let size: CGFloat
    let phase: OrbPhase
    let kind: AnimalAvatarKind
    @State private var animate = false

    var body: some View {
        ZStack {
            if kind == .cat {
                ear(x: -0.26, rotation: -18)
                ear(x: 0.26, rotation: 18)
            } else {
                floppyEar(x: -0.34, rotation: -22)
                floppyEar(x: 0.34, rotation: 22)
            }

            Circle()
                .fill(faceGradient)
                .shadow(color: accent.opacity(phase == .listening ? 0.52 : 0.28), radius: phase == .listening ? 26 : 15)
                .overlay(Circle().stroke(.white.opacity(0.24), lineWidth: 1))

            HStack(spacing: size * 0.18) {
                Circle()
                    .fill(.black.opacity(0.68))
                    .frame(width: size * 0.085, height: size * 0.105)
                Circle()
                    .fill(.black.opacity(0.68))
                    .frame(width: size * 0.085, height: size * 0.105)
            }
            .offset(y: -size * 0.08)

            Circle()
                .fill(.black.opacity(0.54))
                .frame(width: size * 0.08, height: size * 0.055)
                .offset(y: size * 0.05)

            Capsule()
                .fill(.black.opacity(0.50))
                .frame(width: size * (phase == .listening ? 0.30 : 0.18), height: size * 0.035)
                .offset(y: size * 0.18)
                .scaleEffect(y: phase == .listening && animate ? 1.5 : 1)
                .animation(.easeInOut(duration: 0.34).repeatForever(autoreverses: true), value: animate)

            if kind == .cat {
                whiskers
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(phase == .listening ? 1.04 : 1)
        .onAppear { animate = true }
    }

    private var accent: Color {
        kind == .cat ? Color(red: 0.96, green: 0.50, blue: 0.82) : Color(red: 0.42, green: 0.90, blue: 0.78)
    }

    private var faceGradient: LinearGradient {
        if kind == .cat {
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.70, blue: 0.90), Color(red: 0.42, green: 0.62, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [Color(red: 0.45, green: 0.98, blue: 0.88), Color(red: 0.46, green: 0.58, blue: 1.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func ear(x: CGFloat, rotation: Double) -> some View {
        Triangle()
            .fill(faceGradient)
            .frame(width: size * 0.34, height: size * 0.30)
            .rotationEffect(.degrees(rotation))
            .offset(x: size * x, y: -size * 0.37)
    }

    private func floppyEar(x: CGFloat, rotation: Double) -> some View {
        RoundedRectangle(cornerRadius: size * 0.15, style: .continuous)
            .fill(accent.opacity(0.92))
            .frame(width: size * 0.23, height: size * 0.42)
            .rotationEffect(.degrees(rotation))
            .offset(x: size * x, y: -size * 0.08)
    }

    private var whiskers: some View {
        VStack(spacing: size * 0.045) {
            whiskerLine(y: -4)
            whiskerLine(y: 4)
        }
        .offset(y: size * 0.10)
    }

    private func whiskerLine(y: CGFloat) -> some View {
        HStack(spacing: size * 0.30) {
            Capsule()
                .fill(.white.opacity(0.70))
                .frame(width: size * 0.20, height: 1.2)
            Capsule()
                .fill(.white.opacity(0.70))
                .frame(width: size * 0.20, height: 1.2)
        }
        .offset(y: y)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct IconCircle: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .frame(width: 30, height: 30)
                .background(.white.opacity(0.10), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.14), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help(label)
    }
}

struct MouthTranscriptBubble: View {
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Triangle()
                .fill(.white.opacity(0.13))
                .frame(width: 12, height: 16)
                .rotationEffect(.degrees(-90))
            Text(text)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.94))
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.white.opacity(0.13), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.cyan.opacity(0.32), lineWidth: 1)
                )
        }
    }
}

struct ThinkingBars: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(.cyan.opacity(0.55))
                    .frame(width: 24 + CGFloat(index) * 18, height: 6)
                    .opacity(animate ? 0.85 : 0.28)
                    .animation(.easeInOut(duration: 0.72).repeatForever().delay(Double(index) * 0.14), value: animate)
            }
        }
        .onAppear { animate = true }
    }
}

struct PanelBackground: View {
    var body: some View {
        ZStack {
            PanelDragSurface()
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(.black.opacity(0.58))
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.cyan.opacity(0.13), .indigo.opacity(0.11), .pink.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        }
    }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.7 : 0.94))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(configuration.isPressed ? 0.08 : 0.12), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 1))
    }
}

struct GlassGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            configuration.label
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
            configuration.content
        }
        .padding(14)
        .foregroundStyle(.white.opacity(0.88))
        .background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.16), lineWidth: 1))
    }
}
