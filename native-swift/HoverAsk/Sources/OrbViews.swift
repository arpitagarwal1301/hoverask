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
            case .chat:
                CompanionChatView(viewModel: viewModel)
            case .listening:
                CompanionChatView(viewModel: viewModel)
            case .thinking:
                CompanionChatView(viewModel: viewModel)
            case .answer:
                CompanionChatView(viewModel: viewModel)
            case .error(let message):
                CompanionChatView(viewModel: viewModel, errorMessage: message)
            case .settings:
                SettingsWithAvatarView(viewModel: viewModel)
            }
        }
        .frame(minWidth: 1, maxWidth: .infinity, minHeight: 1, maxHeight: .infinity)
        .background(Color.clear)
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
    case chat
    case listening
    case thinking
    case answer
    case error
}

struct CompanionChatView: View {
    @ObservedObject var viewModel: OrbViewModel
    @EnvironmentObject private var settings: SettingsStore
    var errorMessage: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
            companionLayout
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var companionLayout: some View {
        VStack(spacing: 1) {
            bubble
                .zIndex(2)
            BubbleTail(direction: .down, tone: mode)
                .zIndex(1)
            avatar
                .zIndex(0)
        }
        .padding(.bottom, 20)
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
        MinimalChatChipView(viewModel: viewModel, mode: mode, errorMessage: errorMessage)
            .frame(width: 398)
    }

    private var mode: CompanionBubbleMode {
        switch viewModel.phase {
        case .chat:
            .chat
        case .listening:
            .listening
        case .thinking:
            .thinking
        case .answer:
            .answer
        case .error:
            .error
        case .idle, .settings:
            .chat
        }
    }
}

struct CompanionBubbleView: View {
    @ObservedObject var viewModel: OrbViewModel
    let title: String
    let bodyText: String
    let mode: CompanionBubbleMode

    var body: some View {
        MinimalChatChipView(viewModel: viewModel, mode: mode, errorMessage: mode == .error ? bodyText : nil)
    }
}

struct MinimalChatChipView: View {
    @ObservedObject var viewModel: OrbViewModel
    @EnvironmentObject private var settings: SettingsStore
    let mode: CompanionBubbleMode
    let errorMessage: String?
    @State private var copiedToken: String?

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 8 : 6) {
            toolbar
            if isExpanded {
                expandedChatView
            } else {
                compactExchangePreview
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .frame(height: isExpanded ? 292 : nil)
        .frame(maxHeight: isExpanded ? 292 : 112)
        .background(chipBackground)
        .shadow(color: shadowColor, radius: 17, x: 0, y: 8)
        .animation(.spring(response: 0.26, dampingFraction: 0.86), value: isExpanded)
    }

    private var toolbar: some View {
        HStack(spacing: 7) {
            MiniIconButton(
                systemName: spokenReplyIcon,
                label: settings.spokenRepliesEnabled ? "Spoken replies on" : "Spoken replies off",
                isActive: settings.spokenRepliesEnabled
            ) {
                viewModel.toggleSpokenReplies()
            }

            providerPill

            Spacer(minLength: 8)

            MiniIconButton(systemName: "gearshape.fill", label: "Settings") {
                viewModel.openSettings()
            }
            MiniIconButton(systemName: isExpanded ? "chevron.up" : "chevron.down", label: isExpanded ? "Compact" : "Expand") {
                viewModel.isChatExpanded.toggle()
            }
            MiniIconButton(systemName: "xmark", label: "Close chat") {
                viewModel.collapse()
            }
        }
        .frame(height: 24)
    }

    private var isExpanded: Bool {
        viewModel.isChatExpanded
    }

    private var compactExchangePreview: some View {
        VStack(alignment: .leading, spacing: 7) {
            transcriptRow
            chipDivider
            answerRow
        }
    }

    private var chipDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.12))
            .frame(height: 1)
            .padding(.leading, 22)
    }

    private var providerPill: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(providerDotColor)
                .frame(width: 6, height: 6)
            Text(providerTitle)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.white.opacity(0.080), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
    }

    private var transcriptRow: some View {
        HStack(alignment: .top, spacing: 8) {
            MiniIconButton(
                systemName: mode == .listening ? "mic.slash.fill" : "mic.fill",
                label: mode == .listening ? "Stop listening" : "Start listening",
                isActive: mode == .listening,
                isDisabled: mode == .thinking
            ) {
                if mode == .listening {
                    viewModel.stopListeningWithoutSubmitting()
                } else {
                    viewModel.startListening()
                }
            }

            ZStack(alignment: .leading) {
                if viewModel.typedPrompt.isEmpty {
                    Text(inputDisplayText)
                        .font(.system(size: 13, weight: inputDisplayIsPlaceholder ? .regular : .medium, design: .rounded))
                        .foregroundStyle(inputDisplayIsPlaceholder ? .white.opacity(0.46) : .white.opacity(0.90))
                        .lineLimit(1)
                        .allowsHitTesting(false)
                }

                TextField("", text: Binding(
                    get: { viewModel.typedPrompt },
                    set: { viewModel.updateTypedPromptFromUser($0) }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
                .onSubmit {
                    viewModel.submitTypedPrompt()
                }
            }

            MiniIconButton(systemName: "doc.on.doc", label: "Copy input", isDisabled: inputTextIsEmpty) {
                copyToPasteboard(inputCopyText, token: "compact-input")
            }
            .overlay(alignment: .topTrailing) {
                copyFeedbackToast(for: "compact-input", xOffset: 8)
            }
            MiniIconButton(systemName: "paperplane.fill", label: "Send input", isDisabled: sendTextIsEmpty) {
                viewModel.submitTypedPrompt()
            }
        }
        .frame(minHeight: 24, alignment: .top)
    }

    private var answerRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: answerIcon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(answerIconColor)
                .frame(width: 14, height: 18)

            answerTextView
                .frame(maxWidth: .infinity, alignment: .leading)

            MiniIconButton(systemName: "doc.on.doc", label: "Copy answer", isDisabled: answerCopyText.isEmpty) {
                copyToPasteboard(answerCopyText, token: "compact-answer")
            }
            .overlay(alignment: .topTrailing) {
                copyFeedbackToast(for: "compact-answer", xOffset: 8)
            }
        }
        .frame(minHeight: 24, alignment: .top)
    }

    @ViewBuilder
    private var answerTextView: some View {
        if isExpanded {
            ScrollView(.vertical, showsIndicators: true) {
                Text(answerText)
                    .font(.system(size: 13, weight: mode == .error ? .medium : .regular, design: .rounded))
                    .foregroundStyle(answerTextColor)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 8)
            }
            .frame(height: 96)
            .overlay(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.white.opacity(0.16))
                    .frame(width: 2)
            }
        } else {
            if mode == .thinking {
                ThinkingDotsText(prefix: "\(thinkingProviderTitle) thinking")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.yellow.opacity(0.84))
                    .lineLimit(1)
            } else {
                Text(answerText)
                    .font(.system(size: 13, weight: mode == .error ? .medium : .regular, design: .rounded))
                    .foregroundStyle(answerTextColor)
                    .lineLimit(1)
            }
        }
    }

    private var expandedChatView: some View {
        VStack(alignment: .leading, spacing: 8) {
            expandedChatTranscript
            chipDivider
            pinnedChatInputRow
        }
    }

    private var expandedChatTranscript: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 9) {
                    if viewModel.sessionExchanges.isEmpty {
                        emptySessionView
                    } else {
                        ForEach(viewModel.sessionExchanges) { exchange in
                            chatExchangeView(exchange)
                                .id(exchange.id)
                        }
                    }

                    if shouldShowDraftInSession {
                        draftBubbleView
                            .id("draft")
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("session-bottom")
                }
                .padding(.trailing, 8)
            }
            .frame(height: 188)
            .overlay(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.white.opacity(0.16))
                    .frame(width: 2)
            }
            .onAppear {
                scrollToLatestChatAnchor(proxy)
            }
            .onChange(of: viewModel.sessionExchanges) { _ in
                withAnimation(.easeOut(duration: 0.18)) {
                    scrollToLatestChatAnchor(proxy)
                }
            }
            .onChange(of: viewModel.typedPrompt) { _ in
                withAnimation(.easeOut(duration: 0.18)) {
                    scrollToLatestChatAnchor(proxy)
                }
            }
        }
    }

    private var emptySessionView: some View {
        HStack(spacing: 8) {
            Image(systemName: "mic.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.cyan.opacity(0.75))
                .frame(width: 14)
            Text("Ask by voice or type a question.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.56))
        }
        .padding(.top, 4)
    }

    private func chatExchangeView(_ exchange: SessionExchange) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            ChatMessageBubble(
                text: exchange.question,
                metadata: "You",
                side: .user,
                iconName: "waveform",
                isError: false,
                isCopied: copiedToken == "question-\(exchange.id.uuidString)",
                copyAction: { copyToPasteboard(exchange.question, token: "question-\(exchange.id.uuidString)") }
            )

            ChatMessageBubble(
                text: exchangeAnswerText(for: exchange),
                metadata: "\(exchange.provider?.title ?? thinkingProviderTitle) · \(exchangeStatusTitle(for: exchange))",
                side: .assistant,
                iconName: exchangeIcon(for: exchange),
                isError: isFailed(exchange),
                isThinking: isPending(exchange),
                isCopied: copiedToken == "answer-\(exchange.id.uuidString)",
                copyAction: { copyToPasteboard(exchange.answer, token: "answer-\(exchange.id.uuidString)") },
                isCopyDisabled: exchange.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
        .padding(.vertical, 2)
    }

    private var draftBubbleView: some View {
        ChatMessageBubble(
            text: viewModel.typedPrompt,
            metadata: mode == .listening ? "Listening draft" : "Draft",
            side: .user,
            iconName: mode == .listening ? "mic.fill" : "keyboard",
            isError: false,
            isCopied: copiedToken == "draft",
            copyAction: { copyToPasteboard(viewModel.typedPrompt, token: "draft") }
        )
        .padding(.vertical, 2)
    }

    private var pinnedChatInputRow: some View {
        HStack(alignment: .center, spacing: 8) {
            MiniIconButton(
                systemName: mode == .listening ? "mic.slash.fill" : "mic.fill",
                label: mode == .listening ? "Stop listening" : "Start listening",
                isActive: mode == .listening,
                isDisabled: mode == .thinking
            ) {
                if mode == .listening {
                    viewModel.stopListeningWithoutSubmitting()
                } else {
                    viewModel.startListening()
                }
            }

            TextField(inputPlaceholder, text: Binding(
                get: { viewModel.typedPrompt },
                set: { viewModel.updateTypedPromptFromUser($0) }
            ))
            .textFieldStyle(.plain)
            .font(.system(size: 12.5, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.92))
            .onSubmit {
                viewModel.submitTypedPrompt()
            }

            MiniIconButton(systemName: "paperplane.fill", label: "Send input", isDisabled: sendTextIsEmpty) {
                viewModel.submitTypedPrompt()
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(.white.opacity(0.055), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.10), lineWidth: 1))
    }

    private var chipBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.black.opacity(0.66))
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.55, blue: 0.54).opacity(mode == .error ? 0.08 : 0.17),
                            Color(red: 0.02, green: 0.14, blue: 0.15).opacity(0.40),
                            Color(red: 0.74, green: 0.92, blue: 0.82).opacity(0.055)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.20),
                            .cyan.opacity(mode == .error ? 0.10 : 0.28),
                            .white.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    private var providerTitle: String {
        viewModel.activeProvider?.title ?? settings.provider.title
    }

    private var providerDotColor: Color {
        switch mode {
        case .error:
            return .pink
        case .thinking:
            return .yellow
        case .listening:
            return .cyan
        case .answer:
            return .green
        case .chat:
            return .white.opacity(0.48)
        }
    }

    private var inputPlaceholder: String {
        switch mode {
        case .chat:
            return "Type or tap mic..."
        case .listening:
            return "Listening..."
        case .thinking, .answer, .error:
            return "Type a follow-up..."
        }
    }

    private var inputDisplayText: String {
        let draft = viewModel.typedPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !draft.isEmpty {
            return draft
        }
        let submitted = viewModel.currentSubmittedQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        if !submitted.isEmpty {
            return submitted
        }
        if !viewModel.inputStatusMessage.isEmpty {
            return viewModel.inputStatusMessage
        }
        return inputPlaceholder
    }

    private var inputDisplayIsPlaceholder: Bool {
        viewModel.typedPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            viewModel.currentSubmittedQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var inputCopyText: String {
        let typed = viewModel.typedPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !typed.isEmpty {
            return typed
        }
        return viewModel.currentSubmittedQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var inputTextIsEmpty: Bool {
        inputCopyText.isEmpty
    }

    private var sendTextIsEmpty: Bool {
        viewModel.typedPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var shouldShowDraftInSession: Bool {
        !viewModel.typedPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var answerText: String {
        if let errorMessage, mode == .error {
            return errorMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let trimmedAnswer = viewModel.currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        if mode == .thinking {
            return "\(thinkingProviderTitle) thinking..."
        }
        if !trimmedAnswer.isEmpty {
            return trimmedAnswer
        }
        switch mode {
        case .chat:
            return "Waiting for your question..."
        case .listening:
            return "I will answer after you finish."
        case .thinking:
            return "Thinking..."
        case .answer:
            return "I do not have an answer yet."
        case .error:
            return "Something needs attention."
        }
    }

    private var answerCopyText: String {
        if mode == .error {
            return errorMessage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        return viewModel.currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func exchangeAnswerText(for exchange: SessionExchange) -> String {
        switch exchange.status {
        case .pending:
            return exchange.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Thinking..." : exchange.answer
        case .answered:
            return exchange.answer
        case .failed(let message):
            return message
        }
    }

    private func exchangeStatusTitle(for exchange: SessionExchange) -> String {
        switch exchange.status {
        case .pending:
            return "Thinking"
        case .answered:
            return "Answered"
        case .failed:
            return "Needs attention"
        }
    }

    private func exchangeIcon(for exchange: SessionExchange) -> String {
        switch exchange.status {
        case .pending:
            return "sparkles"
        case .answered:
            return "sparkles"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private func exchangeIconColor(for exchange: SessionExchange) -> Color {
        switch exchange.status {
        case .pending:
            return .yellow.opacity(0.82)
        case .answered:
            return .cyan.opacity(0.78)
        case .failed:
            return .pink.opacity(0.88)
        }
    }

    private func exchangeAnswerColor(for exchange: SessionExchange) -> Color {
        switch exchange.status {
        case .failed:
            return Color(red: 1, green: 0.82, blue: 0.82)
        default:
            return .white.opacity(0.76)
        }
    }

    private func isFailed(_ exchange: SessionExchange) -> Bool {
        if case .failed = exchange.status {
            return true
        }
        return false
    }

    private func isPending(_ exchange: SessionExchange) -> Bool {
        if case .pending = exchange.status {
            return true
        }
        return false
    }

    private var thinkingProviderTitle: String {
        settings.provider == .auto ? "Provider" : settings.provider.title
    }

    private func scrollToLatestChatAnchor(_ proxy: ScrollViewProxy) {
        if shouldShowDraftInSession {
            proxy.scrollTo("draft", anchor: .top)
        } else if let latestID = viewModel.sessionExchanges.last?.id {
            proxy.scrollTo(latestID, anchor: .top)
        } else {
            proxy.scrollTo("session-bottom", anchor: .bottom)
        }
    }

    private var answerIcon: String {
        switch mode {
        case .thinking:
            return "sparkles"
        case .error:
            return "exclamationmark.triangle.fill"
        default:
            return "sparkles"
        }
    }

    private var answerIconColor: Color {
        mode == .error ? .pink.opacity(0.88) : .cyan.opacity(0.78)
    }

    private var answerTextColor: Color {
        mode == .error ? Color(red: 1, green: 0.82, blue: 0.82) : .white.opacity(0.78)
    }

    private var spokenReplyIcon: String {
        settings.spokenRepliesEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
    }

    private var shadowColor: Color {
        mode == .error ? .pink.opacity(0.12) : .cyan.opacity(0.12)
    }

    @ViewBuilder
    private func copyFeedbackToast(for token: String, xOffset: CGFloat = 0) -> some View {
        if copiedToken == token {
            CopyFeedbackPill()
                .offset(x: xOffset, y: -26)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
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
            copiedToken = token
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if copiedToken == token {
                withAnimation(.easeIn(duration: 0.14)) {
                    copiedToken = nil
                }
            }
        }
    }
}

enum ChatBubbleSide {
    case user
    case assistant
}

struct ChatMessageBubble: View {
    let text: String
    let metadata: String
    let side: ChatBubbleSide
    let iconName: String
    var isError = false
    var isThinking = false
    var isCopied = false
    let copyAction: () -> Void
    var isCopyDisabled = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if side == .user {
                Spacer(minLength: 36)
            }

            bubble
                .frame(maxWidth: 308, alignment: side == .user ? .trailing : .leading)

            if side == .assistant {
                Spacer(minLength: 36)
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: side == .user ? .trailing : .leading, spacing: 5) {
            HStack(spacing: 5) {
                if side == .assistant {
                    Image(systemName: iconName)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                Text(metadata)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(metadataColor)
                    .lineLimit(1)

                if side == .user {
                    Image(systemName: iconName)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
            }

            HStack(alignment: .top, spacing: 6) {
                if side == .user {
                    MiniIconButton(
                        systemName: "doc.on.doc",
                        label: "Copy question",
                        isDisabled: isCopyDisabled
                    ) {
                        copyAction()
                    }
                    .overlay(alignment: .topLeading) {
                        copyFeedbackToast(xOffset: -2)
                    }
                }

                if isThinking {
                    ThinkingDotsText(prefix: "Thinking")
                        .font(.system(size: 12.2, weight: .medium, design: .rounded))
                        .foregroundStyle(.yellow.opacity(0.84))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(side == .user ? .trailing : .leading)
                } else {
                    Text(text)
                        .font(.system(size: 12.2, weight: side == .user ? .medium : .regular, design: .rounded))
                        .foregroundStyle(textColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(side == .user ? .trailing : .leading)
                }

                if side == .assistant {
                    MiniIconButton(
                        systemName: "doc.on.doc",
                        label: "Copy answer",
                        isDisabled: isCopyDisabled
                    ) {
                        copyAction()
                    }
                    .overlay(alignment: .topTrailing) {
                        copyFeedbackToast(xOffset: 2)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(backgroundShape)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(strokeColor, lineWidth: 1)
        )
    }

    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                LinearGradient(
                    colors: backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var backgroundColors: [Color] {
        switch side {
        case .user:
            return [
                Color(red: 0.12, green: 0.42, blue: 0.43).opacity(0.54),
                Color(red: 0.04, green: 0.19, blue: 0.21).opacity(0.76)
            ]
        case .assistant:
            if isError {
                return [
                    Color(red: 0.35, green: 0.10, blue: 0.16).opacity(0.54),
                    Color(red: 0.10, green: 0.06, blue: 0.08).opacity(0.76)
                ]
            }
            return [
                Color.white.opacity(0.075),
                Color(red: 0.02, green: 0.15, blue: 0.16).opacity(0.62)
            ]
        }
    }

    private var strokeColor: Color {
        switch side {
        case .user:
            return .cyan.opacity(0.18)
        case .assistant:
            return isError ? .pink.opacity(0.18) : .white.opacity(0.12)
        }
    }

    private var metadataColor: Color {
        switch side {
        case .user:
            return .white.opacity(0.58)
        case .assistant:
            return isError ? .pink.opacity(0.78) : .cyan.opacity(0.70)
        }
    }

    private var iconColor: Color {
        switch side {
        case .user:
            return .cyan.opacity(0.70)
        case .assistant:
            return isError ? .pink.opacity(0.82) : .cyan.opacity(0.72)
        }
    }

    private var textColor: Color {
        isError ? Color(red: 1, green: 0.82, blue: 0.82) : .white.opacity(side == .user ? 0.90 : 0.78)
    }

    @ViewBuilder
    private func copyFeedbackToast(xOffset: CGFloat) -> some View {
        if isCopied {
            CopyFeedbackPill()
                .offset(x: xOffset, y: -26)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
    }
}

struct CopyFeedbackPill: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark")
                .font(.system(size: 8, weight: .bold))
            Text("Copied")
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundStyle(Color(red: 1.0, green: 0.68, blue: 0.38).opacity(0.96))
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(Color.orange.opacity(0.28), lineWidth: 1))
        .shadow(color: Color.orange.opacity(0.16), radius: 8, x: 0, y: 3)
    }
}

struct ThinkingDotsText: View {
    let prefix: String

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.36)) { context in
            let tick = Int(context.date.timeIntervalSinceReferenceDate / 0.36) % 4
            Text(prefix + String(repeating: ".", count: max(tick, 1)))
        }
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

struct SettingsWithAvatarView: View {
    @ObservedObject var viewModel: OrbViewModel
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            SettingsPanel(viewModel: viewModel)

            AvatarVisual(style: settings.avatarStyle, size: 82, phase: .idle, motion: .idle)
                .overlay(
                    ClickDragOverlay(
                        onClick: { viewModel.closeSettings() },
                        onHoldStart: { viewModel.holdBegan() },
                        onHoldEnd: { viewModel.holdEnded() },
                        onDragStart: { viewModel.dragStarted() },
                        onDragEnd: { viewModel.dragEnded() }
                    )
                )
                .padding(18)
        }
    }
}

struct SettingsPanel: View {
    @ObservedObject var viewModel: OrbViewModel
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var history: HistoryStore
    @State private var visibleHistoryCount = 5

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
                    ForEach(providerPickerOptions) { provider in
                        Text(provider.title).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                Text("Only ready CLI providers appear in the Provider picker.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))

                Picker("Assistant", selection: $settings.avatarStyle) {
                    ForEach(AvatarStyle.allCases) { style in
                        Text(style.title).tag(style)
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

                Divider().overlay(.white.opacity(0.12))

                Text("Cursor, OpenCode, and Antigravity use each CLI's configured default model.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.60))
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
                    cliProviderRow(health)
                }

                providerPlannedRow(
                    title: "GitHub Copilot CLI",
                    detail: "Planned - no reliable non-interactive gh copilot command is installed.",
                    url: URL(string: "https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/overview")
                )
            }
        } label: {
            Text("CLI providers")
        }
        .groupBoxStyle(GlassGroupBoxStyle())
    }

    private var historyGroup: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Keep local history", isOn: $settings.historyEnabled)
                HStack {
                    Text("\(history.items.count) saved · \(formattedHistorySize)")
                    Spacer()
                    Button("Clear history") {
                        viewModel.clearHistory()
                        visibleHistoryCount = 5
                    }
                    .buttonStyle(GlassButtonStyle())
                    .disabled(history.items.isEmpty)
                }
                ForEach(history.items.prefix(visibleHistoryCount)) { item in
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
                if visibleHistoryCount < history.items.count {
                    Button("Load more") {
                        visibleHistoryCount = min(visibleHistoryCount + 10, history.items.count)
                    }
                    .buttonStyle(GlassButtonStyle())
                }
            }
        } label: {
            Text("Local history")
        }
        .groupBoxStyle(GlassGroupBoxStyle())
    }

    private var providerPickerOptions: [ProviderSelection] {
        var options: [ProviderSelection] = [.auto]
        for provider in [AssistantProvider.codex, .claude, .cursor, .opencode, .antigravity] {
            if isReady(provider) {
                options.append(provider.selection)
            }
        }
        if !options.contains(settings.provider) {
            DispatchQueue.main.async {
                settings.provider = .auto
            }
        }
        return options
    }

    private func isReady(_ provider: AssistantProvider) -> Bool {
        guard let health = viewModel.providerHealth.first(where: { $0.provider == provider }) else {
            return provider == .codex || provider == .claude
        }
        return health.installed && health.authenticated
    }

    private func cliProviderRow(_ health: ProviderHealth) -> some View {
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
                    .lineLimit(2)
            }
            Spacer()
            if let url = docsURL(for: health.provider), !health.authenticated {
                MiniIconButton(systemName: "info.circle", label: "Provider info") {
                    NSWorkspace.shared.open(url)
                }
            }
            if health.installed && supportsLogin(health.provider) {
                Button(health.authenticated ? "Re-login" : "Login") {
                    viewModel.login(provider: health.provider)
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
    }

    private func providerPlannedRow(title: String, detail: String, url: URL?) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.gray.opacity(0.80))
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
            }
            Spacer()
            if let url {
                MiniIconButton(systemName: "info.circle", label: "Provider info") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private func supportsLogin(_ provider: AssistantProvider) -> Bool {
        provider.category == .cli && provider != .antigravity
    }

    private func docsURL(for provider: AssistantProvider) -> URL? {
        switch provider {
        case .codex:
            return URL(string: "https://developers.openai.com/codex/")
        case .claude:
            return URL(string: "https://code.claude.com/docs/en/overview")
        case .cursor:
            return URL(string: "https://cursor.com/cli")
        case .opencode:
            return URL(string: "https://opencode.ai/docs/cli/")
        case .antigravity:
            return URL(string: "https://antigravity.google/docs/cli-using")
        case .appleIntelligence:
            return URL(string: "https://developer.apple.com/apple-intelligence/")
        case .ollama:
            return URL(string: "https://ollama.com/download")
        case .lmStudio:
            return URL(string: "https://lmstudio.ai/")
        case .openAI:
            return URL(string: "https://platform.openai.com/api-keys")
        case .anthropic:
            return URL(string: "https://console.anthropic.com/settings/keys")
        case .gemini:
            return URL(string: "https://aistudio.google.com/app/apikey")
        case .openRouter:
            return URL(string: "https://openrouter.ai/keys")
        case .groq:
            return URL(string: "https://console.groq.com/keys")
        }
    }

    private var formattedHistorySize: String {
        let bytes = Double(history.storageSizeBytes)
        if bytes < 1024 {
            return "\(Int(bytes)) B"
        }
        if bytes < 1024 * 1024 {
            return "\(Int((bytes / 1024).rounded())) KB"
        }
        let megabytes = bytes / 1024 / 1024
        return String(format: "%.1f MB", megabytes)
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
            let image = BundleImageLoader.image(named: assetName)

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
        case .idle, .chat:
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let breathe = reduceMotion ? 0 : sin(time * 1.08)
            let drift = reduceMotion ? 0 : sin(time * 0.54)
            let pulse = reduceMotion ? 0.5 : (phase == .listening ? (sin(time * 4.0) + 1) / 2 : (sin(time * 1.35) + 1) / 2)
            let ivory = Color(red: 0.93, green: 0.99, blue: 0.95)
            let mint = Color(red: 0.66, green: 1.0, blue: 0.94)
            let cyan = Color(red: 0.11, green: 0.86, blue: 0.80)
            let rimTeal = Color(red: 0.22, green: 0.68, blue: 0.62)
            let deepTeal = Color(red: 0.035, green: 0.30, blue: 0.31)
            let smokeTeal = Color(red: 0.016, green: 0.13, blue: 0.15)
            let blackGlass = Color(red: 0.006, green: 0.010, blue: 0.014)
            let copper = Color(red: 0.86, green: 0.54, blue: 0.32)

            ZStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                smokeTeal.opacity(0.18),
                                cyan.opacity(0.045),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.28
                        )
                    )
                    .frame(width: size * 0.52, height: size * 0.14)
                    .offset(y: size * 0.31)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                cyan.opacity(rimGlowOpacity + breathe * 0.006),
                                rimTeal.opacity(0.020),
                                .clear
                            ],
                            center: UnitPoint(x: 0.45, y: 0.44),
                            startRadius: 0,
                            endRadius: size * 0.43
                        )
                    )
                    .frame(width: size * 0.82, height: size * 0.82)

                ForEach(0..<rippleCount, id: \.self) { index in
                    OrbRippleRing(
                        size: size,
                        index: index,
                        time: time,
                        pulse: CGFloat(pulse),
                        strength: rippleStrength,
                        baseScale: rippleBaseScale,
                        step: rippleStep,
                        isListening: phase == .listening,
                        isThinking: phase == .thinking,
                        reduceMotion: reduceMotion,
                        shadowColor: smokeTeal,
                        accentColor: cyan,
                        highlightColor: mint
                    )
                }

                OrbCoreGlass(
                    size: size,
                    phase: phase,
                    time: time,
                    breathe: CGFloat(breathe),
                    drift: CGFloat(drift),
                    reduceMotion: reduceMotion,
                    ivory: ivory,
                    mint: mint,
                    cyan: cyan,
                    deepTeal: deepTeal,
                    smokeTeal: smokeTeal,
                    blackGlass: blackGlass,
                    copper: copper
                )
            }
            .frame(width: size, height: size)
            .scaleEffect(phase == .listening ? 1.030 : 1)
        }
    }

    private var rippleCount: Int {
        switch phase {
        case .idle, .chat, .settings:
            return 3
        case .listening:
            return 5
        case .thinking:
            return 3
        case .answer:
            return 5
        case .error:
            return 2
        }
    }

    private var rippleStrength: Double {
        switch phase {
        case .idle, .chat, .settings:
            return 0.82
        case .listening:
            return 1.24
        case .thinking:
            return 0.92
        case .answer:
            return 1.04
        case .error:
            return 0.66
        }
    }

    private var rippleBaseScale: CGFloat {
        switch phase {
        case .idle, .chat, .settings, .error:
            return 0.64
        case .thinking:
            return 0.67
        case .listening, .answer:
            return 0.72
        }
    }

    private var rippleStep: CGFloat {
        switch phase {
        case .idle, .chat, .settings, .error:
            return 0.052
        case .thinking:
            return 0.070
        case .listening:
            return 0.088
        case .answer:
            return 0.090
        }
    }

    private var rimGlowOpacity: Double {
        switch phase {
        case .listening:
            return 0.090
        case .answer:
            return 0.072
        case .thinking:
            return 0.062
        case .error:
            return 0.042
        case .idle, .chat, .settings:
            return 0.055
        }
    }
}

private struct OrbCoreGlass: View {
    let size: CGFloat
    let phase: OrbPhase
    let time: TimeInterval
    let breathe: CGFloat
    let drift: CGFloat
    let reduceMotion: Bool
    let ivory: Color
    let mint: Color
    let cyan: Color
    let deepTeal: Color
    let smokeTeal: Color
    let blackGlass: Color
    let copper: Color

    var body: some View {
        Circle()
            .fill(coreFill)
            .frame(width: size * 0.60, height: size * 0.60)
            .overlay(lowerShade)
            .overlay(tealBodyReflection)
            .overlay(lensRefraction)
            .overlay(rimStroke)
            .overlay(innerDarkRim)
            .overlay(dogGlassReflections)
            .overlay(mainHighlight)
            .overlay(movingRimGlint)
            .overlay(copperCrescent)
            .overlay(OrbGlassGrain(size: size))
            .overlay(innerCyanEdge)
            .shadow(color: cyan.opacity(phase == .listening ? 0.20 : 0.10), radius: phase == .listening ? 8 : 5, x: -1, y: 3)
            .shadow(color: smokeTeal.opacity(0.26), radius: 6, x: 4, y: 6)
            .shadow(color: .black.opacity(0.18), radius: 5, y: 6)
            .scaleEffect(1 + breathe * 0.010)
            .rotationEffect(.degrees(reduceMotion ? 0 : Double(drift) * 0.55))
    }

    private var coreFill: RadialGradient {
        RadialGradient(
            colors: [
                ivory.opacity(0.68),
                mint.opacity(0.44),
                cyan.opacity(0.50),
                deepTeal.opacity(0.92),
                blackGlass.opacity(0.94)
            ],
            center: UnitPoint(x: 0.31, y: 0.24),
            startRadius: 2,
            endRadius: size * 0.45
        )
    }

    private var lowerShade: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .clear,
                        smokeTeal.opacity(0.18),
                        blackGlass.opacity(0.58)
                    ],
                    center: UnitPoint(x: 0.72, y: 0.68),
                    startRadius: size * 0.04,
                    endRadius: size * 0.33
                )
            )
    }

    private var tealBodyReflection: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        cyan.opacity(0.34),
                        deepTeal.opacity(0.15),
                        .clear
                    ],
                    center: UnitPoint(x: 0.40 + drift * 0.025, y: 0.42),
                    startRadius: 0,
                    endRadius: size * 0.22
                )
            )
            .blur(radius: 0.3)
    }

    private var lensRefraction: some View {
        OrbLensRefraction(
            size: size,
            phase: phase,
            time: time,
            reduceMotion: reduceMotion,
            ivory: ivory,
            mint: mint,
            cyan: cyan,
            deepTeal: deepTeal,
            smokeTeal: smokeTeal
        )
    }

    private var rimStroke: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: [
                        ivory.opacity(0.78),
                        mint.opacity(0.66),
                        cyan.opacity(0.70),
                        smokeTeal.opacity(0.52),
                        cyan.opacity(0.55),
                        ivory.opacity(0.64)
                    ],
                    center: .center
                ),
                lineWidth: 1.35
            )
    }

    private var innerDarkRim: some View {
        Circle()
            .stroke(smokeTeal.opacity(0.42), lineWidth: 0.8)
            .padding(size * 0.018)
    }

    private var dogGlassReflections: some View {
        OrbDogGlassReflections(
            size: size,
            time: time,
            reduceMotion: reduceMotion,
            ivory: ivory,
            mint: mint,
            cyan: cyan,
            deepTeal: deepTeal,
            smokeTeal: smokeTeal
        )
    }

    private var mainHighlight: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        ivory.opacity(0.76),
                        ivory.opacity(0.30),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.12
                )
            )
            .frame(width: size * 0.23, height: size * 0.16)
            .rotationEffect(.degrees(-24))
            .offset(x: -size * 0.115, y: -size * 0.135)
    }

    private var movingRimGlint: some View {
        Circle()
            .trim(from: 0.025, to: 0.145)
            .stroke(
                LinearGradient(
                    colors: [
                        ivory.opacity(0.68),
                        mint.opacity(0.54),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1.55, lineCap: .round)
            )
            .rotationEffect(.degrees(reduceMotion ? -42 : time * 10 - 42))
            .padding(size * 0.018)
    }

    private var copperCrescent: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        copper.opacity(0.16),
                        ivory.opacity(0.08),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size * 0.21, height: size * 0.050)
            .rotationEffect(.degrees(-36))
            .offset(x: size * 0.142, y: size * 0.190)
            .blur(radius: 0.45)
            .blendMode(.screen)
    }

    private var innerCyanEdge: some View {
        Circle()
            .stroke(cyan.opacity(0.24), lineWidth: size * 0.012)
            .blur(radius: 0.45)
            .padding(size * 0.034)
    }
}

private struct OrbLensRefraction: View {
    let size: CGFloat
    let phase: OrbPhase
    let time: TimeInterval
    let reduceMotion: Bool
    let ivory: Color
    let mint: Color
    let cyan: Color
    let deepTeal: Color
    let smokeTeal: Color

    var body: some View {
        let motion = reduceMotion ? 0 : time * motionSpeed
        let drift = CGFloat(sin(motion))
        let counterDrift = CGFloat(cos(motion * 0.74))

        ZStack {
            magnifiedLightPatch(drift: drift)
            warpedTealBand(drift: drift, counterDrift: counterDrift)
            invertedReflectionPatch(counterDrift: counterDrift)
            innerCausticBands(drift: drift)
            lensEdgeThickness(drift: drift)
        }
        .frame(width: size * 0.60, height: size * 0.60)
        .clipShape(Circle())
    }

    private var motionSpeed: Double {
        switch phase {
        case .listening:
            return 1.05
        case .thinking, .answer:
            return 0.70
        case .idle, .chat, .settings, .error:
            return 0.34
        }
    }

    private var phaseBoost: Double {
        switch phase {
        case .listening:
            return 1.18
        case .thinking, .answer:
            return 1.06
        case .idle, .chat, .settings:
            return 0.94
        case .error:
            return 0.80
        }
    }

    private func magnifiedLightPatch(drift: CGFloat) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        ivory.opacity(0.20 * phaseBoost),
                        mint.opacity(0.080 * phaseBoost),
                        cyan.opacity(0.035 * phaseBoost),
                        .clear
                    ],
                    center: UnitPoint(x: 0.36 + drift * 0.08, y: 0.36),
                    startRadius: 0,
                    endRadius: size * 0.18
                )
            )
            .frame(width: size * 0.34, height: size * 0.20)
            .rotationEffect(.degrees(-18 + Double(drift) * 2.4))
            .offset(x: -size * 0.030 + drift * size * 0.018, y: -size * 0.030)
            .blendMode(.screen)
    }

    private func warpedTealBand(drift: CGFloat, counterDrift: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        cyan.opacity(0.13 * phaseBoost),
                        mint.opacity(0.075 * phaseBoost),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size * 0.042, height: size * 0.42)
            .rotationEffect(.degrees(53 + Double(drift) * 3.4))
            .offset(x: counterDrift * size * 0.018, y: drift * size * 0.010)
            .blur(radius: 0.35)
            .blendMode(.screen)
    }

    private func invertedReflectionPatch(counterDrift: CGFloat) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        smokeTeal.opacity(0.22),
                        deepTeal.opacity(0.10),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.14
                )
            )
            .frame(width: size * 0.30, height: size * 0.13)
            .rotationEffect(.degrees(15 - Double(counterDrift) * 2))
            .offset(x: size * 0.070, y: size * 0.105 + counterDrift * size * 0.006)
            .blendMode(.multiply)
    }

    private func innerCausticBands(drift: CGFloat) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .trim(from: causticStart(index), to: causticStart(index) + causticLength(index))
                    .stroke(
                        index == 1 ? mint.opacity(0.14 * phaseBoost) : ivory.opacity(0.12 * phaseBoost),
                        style: StrokeStyle(lineWidth: index == 1 ? 0.70 : 0.55, lineCap: .round)
                    )
                    .rotationEffect(.degrees(Double(index) * 44 + Double(drift) * 5))
                    .padding(size * (0.12 + CGFloat(index) * 0.030))
                    .blendMode(.screen)
            }
        }
    }

    private func lensEdgeThickness(drift: CGFloat) -> some View {
        ZStack {
            Circle()
                .trim(from: 0.58, to: 0.86)
                .stroke(
                    smokeTeal.opacity(0.32),
                    style: StrokeStyle(lineWidth: 2.0, lineCap: .round)
                )
                .rotationEffect(.degrees(8 + Double(drift) * 1.4))
                .padding(size * 0.020)

            Circle()
                .trim(from: 0.09, to: 0.31)
                .stroke(
                    LinearGradient(
                        colors: [
                            ivory.opacity(0.28),
                            mint.opacity(0.18),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 1.35, lineCap: .round)
                )
                .rotationEffect(.degrees(-24 - Double(drift) * 1.6))
                .padding(size * 0.022)
                .blendMode(.screen)
        }
    }

    private func causticStart(_ index: Int) -> CGFloat {
        switch index {
        case 0: return 0.085
        case 1: return 0.345
        default: return 0.735
        }
    }

    private func causticLength(_ index: Int) -> CGFloat {
        switch index {
        case 0: return 0.095
        case 1: return 0.070
        default: return 0.060
        }
    }
}

private struct OrbRippleRing: View {
    let size: CGFloat
    let index: Int
    let time: TimeInterval
    let pulse: CGFloat
    let strength: Double
    let baseScale: CGFloat
    let step: CGFloat
    let isListening: Bool
    let isThinking: Bool
    let reduceMotion: Bool
    let shadowColor: Color
    let accentColor: Color
    let highlightColor: Color

    var body: some View {
        let ringSize = size * (baseScale + CGFloat(index) * step + pulse * liveScale)
        let rotation = reduceMotion ? 0 : time * rotationSpeed + Double(index) * 31
        let baseOpacity = min(0.72, max(0.0, 0.40 * strength - Double(index) * 0.044))
        let accentOpacity = min(0.86, max(0.0, 0.56 * strength - Double(index) * 0.060))
        let whisperOpacity = min(0.24, max(0.0, 0.13 * strength - Double(index) * 0.018))
        let baseLineWidth = isListening ? 2.35 : 1.90
        let accentLineWidth = isListening ? 1.32 : 1.08

        ZStack {
            Circle()
                .stroke(
                    highlightColor.opacity(whisperOpacity),
                    style: StrokeStyle(lineWidth: 0.72, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(rotation))

            ForEach(0..<4, id: \.self) { segment in
                Circle()
                    .trim(from: segmentStart(segment), to: segmentStart(segment) + segmentLength(segment))
                    .stroke(
                        shadowColor.opacity(baseOpacity),
                        style: StrokeStyle(lineWidth: baseLineWidth, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(rotation))

                Circle()
                    .trim(from: segmentStart(segment) + 0.010, to: segmentStart(segment) + segmentLength(segment) - 0.016)
                    .stroke(
                        segment == 1 ? highlightColor.opacity(accentOpacity * 0.72) : accentColor.opacity(accentOpacity),
                        style: StrokeStyle(lineWidth: accentLineWidth, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(rotation + 1.5))
            }
        }
    }

    private var rotationSpeed: Double {
        if isListening {
            return 11.5 + Double(index) * 1.4
        }
        return (isThinking ? 8.5 : 4.8) + Double(index) * 0.55
    }

    private var liveScale: CGFloat {
        if reduceMotion {
            return 0
        }
        if isListening {
            return index == 0 ? 0.026 : 0.035
        }
        return index == 0 ? 0.010 : 0.015
    }

    private func segmentStart(_ segment: Int) -> CGFloat {
        switch segment {
        case 0: return 0.055
        case 1: return 0.315
        case 2: return 0.575
        default: return 0.805
        }
    }

    private func segmentLength(_ segment: Int) -> CGFloat {
        switch segment {
        case 0: return 0.205
        case 1: return 0.165
        case 2: return 0.145
        default: return 0.105
        }
    }
}

private struct OrbDogGlassReflections: View {
    let size: CGFloat
    let time: TimeInterval
    let reduceMotion: Bool
    let ivory: Color
    let mint: Color
    let cyan: Color
    let deepTeal: Color
    let smokeTeal: Color

    var body: some View {
        let drift = reduceMotion ? CGFloat.zero : CGFloat(sin(time * 0.52))
        let counterDrift = reduceMotion ? CGFloat.zero : CGFloat(cos(time * 0.38))

        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            mint.opacity(0.00),
                            mint.opacity(0.13),
                            cyan.opacity(0.10),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.38, height: size * 0.16)
                .rotationEffect(.degrees(-21 + drift * 2.0))
                .offset(x: -size * 0.01 + drift * size * 0.012, y: size * 0.005)
                .blendMode(.screen)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            ivory.opacity(0.00),
                            mint.opacity(0.20),
                            cyan.opacity(0.13),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.026, height: size * 0.35)
                .rotationEffect(.degrees(9 + counterDrift * 1.2))
                .offset(x: -size * 0.105, y: size * 0.035 + counterDrift * size * 0.006)
                .blur(radius: 0.25)
                .blendMode(.screen)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            deepTeal.opacity(0.18),
                            smokeTeal.opacity(0.10),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.18
                    )
                )
                .frame(width: size * 0.34, height: size * 0.18)
                .rotationEffect(.degrees(18))
                .offset(x: size * 0.065, y: size * 0.105)
                .blendMode(.multiply)

            Circle()
                .trim(from: 0.58, to: 0.74)
                .stroke(
                    cyan.opacity(0.20),
                    style: StrokeStyle(lineWidth: 1.1, lineCap: .round)
                )
                .rotationEffect(.degrees(6 + drift * 4))
                .padding(size * 0.075)
                .blendMode(.screen)
        }
        .frame(width: size * 0.60, height: size * 0.60)
        .clipShape(Circle())
    }
}

private struct OrbGlassGrain: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<34, id: \.self) { index in
                Circle()
                    .fill(index % 4 == 0 ? Color.white.opacity(0.018) : Color.cyan.opacity(0.010))
                    .frame(width: dotSize(index), height: dotSize(index))
                    .offset(x: dotOffsetX(index), y: dotOffsetY(index))
            }
        }
        .frame(width: size * 0.58, height: size * 0.58)
        .clipShape(Circle())
        .blendMode(.screen)
    }

    private func dotSize(_ index: Int) -> CGFloat {
        CGFloat(0.65 + Double((index * 7) % 5) * 0.10)
    }

    private func dotOffsetX(_ index: Int) -> CGFloat {
        let normalized = CGFloat((index * 37) % 100) / 100 - 0.5
        return normalized * size * 0.48
    }

    private func dotOffsetY(_ index: Int) -> CGFloat {
        let normalized = CGFloat((index * 53) % 100) / 100 - 0.5
        return normalized * size * 0.48
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

struct MiniIconButton: View {
    let systemName: String
    let label: String
    var isActive = false
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(foregroundColor)
                .frame(width: 22, height: 22)
                .background(backgroundColor, in: Circle())
                .overlay(Circle().stroke(strokeColor, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.38 : 1)
        .help(label)
    }

    private var foregroundColor: Color {
        if isActive {
            return .cyan.opacity(0.96)
        }
        return .white.opacity(0.78)
    }

    private var backgroundColor: Color {
        if isActive {
            return .cyan.opacity(0.13)
        }
        return .white.opacity(0.075)
    }

    private var strokeColor: Color {
        if isActive {
            return .cyan.opacity(0.28)
        }
        return .white.opacity(0.12)
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
                .fill(.black.opacity(0.82))
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.cyan.opacity(0.10), .indigo.opacity(0.08), .pink.opacity(0.055)],
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
        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.20), lineWidth: 1))
    }
}
