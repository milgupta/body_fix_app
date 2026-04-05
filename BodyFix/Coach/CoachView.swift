import SwiftUI
import SwiftData

struct CoachView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \StretchSession.date, order: .reverse) private var sessions: [StretchSession]

    @State private var messages: [CoachChatMessage] = []
    @State private var input = ""
    @State private var isSending = false
    @State private var showTyping = false

    private var profile: UserProfile? { profiles.first }
    private var isPro: Bool { profile?.subscriptionActive == true }

    private let suggestions = [
        "Why does my back hurt after sitting?",
        "What should I stretch before running?",
        "How often should I stretch?",
        "Best stretches for posture"
    ]

    var body: some View {
        ZStack {
            Color.bfBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Text("AI Coach")
                        .font(Typography.screenTitle)
                        .foregroundStyle(Color.bfTextPrimary)
                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.bfMint)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)

                ZStack {
                    chatContent
                        .blur(radius: isPro ? 0 : 6)
                        .disabled(!isPro)

                    if !isPro {
                        paywallOverlay
                    }
                }
            }
        }
    }

    private var chatContent: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            CoachMessageBubble(message: message)
                                .id(message.id)
                        }
                        if showTyping {
                            typingIndicator
                                .id("typing")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: showTyping) { _, typing in
                    if typing {
                        withAnimation {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            }

            if messages.isEmpty && isPro {
                suggestionPills
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Ask about stretching...", text: $input, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(Typography.stretchDescription)
                    .foregroundStyle(Color.bfTextPrimary)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.bfSurfaceElevated))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.bfBorder))

                Button {
                    sendCurrentInput()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.bfTextDisabled : Color.bfMint)
                }
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending || !isPro)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.bfBackground.opacity(0.95))
        }
    }

    private var suggestionPills: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(suggestions, id: \.self) { prompt in
                Button {
                    input = prompt
                    sendCurrentInput()
                } label: {
                    Text(prompt)
                        .font(Typography.caption)
                        .foregroundStyle(Color.bfTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.bfSurfaceElevated))
                        .overlay(Capsule().stroke(Color.bfBorder))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< 3, id: \.self) { i in
                Circle()
                    .fill(Color.bfTextMuted)
                    .frame(width: 6, height: 6)
                    .opacity(0.4)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(i) * 0.2),
                        value: showTyping
                    )
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.bfSurfaceElevated))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var paywallOverlay: some View {
        VStack(spacing: 16) {
            Text("Unlock AI Coach")
                .font(Typography.navTitle)
                .foregroundStyle(Color.bfTextPrimary)
            Text("Get personalized stretching advice, recovery tips, and answers to your mobility questions.")
                .font(Typography.screenSubtitle)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.bfTextTertiary)
                .padding(.horizontal, 8)

            Button {
                HapticManager.shared.mediumImpact()
                PaywallManager.shared.showPaywall()
                if let p = profile {
                    p.subscriptionActive = true
                    try? modelContext.save()
                }
            } label: {
                Text("Upgrade to Pro")
                    .font(Typography.primaryCta)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.bfGradient))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.bfSurfaceElevated)
                .shadow(color: .black.opacity(0.35), radius: 20, y: 8)
        )
        .padding(24)
    }

    private func sendCurrentInput() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let profile else { return }
        HapticManager.shared.lightImpact()
        input = ""
        messages.append(CoachChatMessage(isUser: true, text: text))
        let historyBefore = messages.dropLast()
        isSending = true
        showTyping = true

        Task {
            do {
                let reply = try await CoachService.shared.send(
                    userText: text,
                    history: Array(historyBefore),
                    profile: profile,
                    recentSessions: Array(sessions.prefix(5))
                )
                await MainActor.run {
                    showTyping = false
                    messages.append(CoachChatMessage(isUser: false, text: reply))
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    showTyping = false
                    messages.append(CoachChatMessage(isUser: false, text: "Couldn't connect. Check your internet and try again."))
                    isSending = false
                }
            }
        }
    }
}

#Preview {
    CoachView()
        .modelContainer(for: [UserProfile.self, StretchSession.self], inMemory: true)
}
