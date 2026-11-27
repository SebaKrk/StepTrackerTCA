//
//  PlanChatView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/11/2026.
//

import ComposableArchitecture
import HealthHub
import SharedModels
import SwiftUI

@ViewAction(for: PlanChatFeature.self)
struct PlanChatView: View {

    // MARK: - Properties

    /// The chat, the typed text and the pending correction.
    @Bindable var store: StoreOf<PlanChatFeature>

    /// Keyboard focus of the message field; the first focus opens the sheet fully (same pattern as ScanPlanView).
    @FocusState private var isInputFocused: Bool

    // MARK: - Body

    var body: some View {
        NavigationStack {
            conversation
                .safeAreaInset(edge: .bottom) { inputBar }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { closeButton }
                }
        }
        .presentationDetents([.medium, .large], selection: detent)
        .onChange(of: isInputFocused) { _, isFocused in
            if isFocused { send(.inputFocused) }
        }
    }

    // MARK: - Structure

    private var conversation: some View {
        ScrollViewReader { proxy in
            messageList
                // Every finished message, the "AI is writing" status and the Apply card pull the chat to the bottom.
                .onChange(of: store.messages.count) { scrollToBottom(proxy) }
                .onChange(of: store.isSending) { scrollToBottom(proxy) }
                .onChange(of: store.proposal) { scrollToBottom(proxy) }
                .onChange(of: store.failure) { scrollToBottom(proxy) }
                .onChange(of: store.isExpanded) { scrollToBottom(proxy) }
                .onChange(of: isInputFocused) { scrollToBottom(proxy) }
        }
    }

    private var messageList: some View {
        ScrollView {
            // A chat holds at most a dozen messages: a plain stack keeps transitions and bottom anchoring steady.
            VStack(alignment: .leading, spacing: 12) {
                greetingBubble
                ForEach(store.messages) { message in
                    messageBubble(message)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                if store.isSending {
                    typingIndicator
                        .transition(.opacity)
                }
                if let proposal = store.proposal {
                    proposalCard(proposal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                if let failure = store.failure {
                    failureRow(failure)
                        .transition(.opacity)
                }
                if store.isMessageLimitReached, store.proposal == nil, store.failure == nil, !store.isSending {
                    limitNotice
                        .transition(.opacity)
                }
                bottomMarker
            }
            .padding(16)
            .animation(.default, value: store.messages)
            .animation(.default, value: store.isSending)
            .animation(.default, value: store.proposal)
            .animation(.default, value: store.failure)
        }
        .defaultScrollAnchor(.bottom, for: .initialOffset)
        .scrollDismissesKeyboard(.interactively)
        // The keyboard goes only when the user taps outside the field.
        .simultaneousGesture(TapGesture().onEnded { isInputFocused = false })
    }

    private var inputBar: some View {
        GlassEffectContainer {
            HStack(alignment: .bottom, spacing: 10) {
                messageField
                sendButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        // Only a used-up chat locks the field: disabling it while the model answers would drop the keyboard.
        .disabled(store.isMessageLimitReached)
        .opacity(store.isMessageLimitReached ? 0.4 : 1)
        .animation(.easeInOut(duration: 0.2), value: store.isMessageLimitReached)
    }

    // MARK: - Implementation

    // Shown as the model's first message; it stays on the phone and never reaches the server.
    private var greetingBubble: some View {
        bubble(text: greetingText, isUser: false)
    }

    private func messageBubble(_ message: PlanChatMessage) -> some View {
        bubble(text: message.text, isUser: message.role == .user)
    }

    private func bubble(text: String, isUser: Bool) -> some View {
        HStack {
            if isUser { Spacer(minLength: 48) }
            Text(text)
                .font(.body)
                .foregroundStyle(isUser ? Color.white : Color.primary)
                .padding(.leading, isUser ? 14 : 20)
                .padding(.trailing, isUser ? 20 : 14)
                .padding(.vertical, 10)
                .background(
                    isUser ? store.color : Color(.secondarySystemBackground),
                    in: ChatBubbleShape(isTailTrailing: isUser)
                )
            if !isUser { Spacer(minLength: 48) }
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
            Text(typingText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func proposalCard(_ proposal: PlanRefinement) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(changesTitle)
                .font(.subheadline.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            ForEach(Array(proposal.changes.enumerated()), id: \.offset) { _, change in
                Label(change, systemImage: "checkmark.circle")
                    .font(.subheadline)
            }
            applyButton
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 20, style: .continuous))
    }

    private var applyButton: some View {
        Button {
            send(.applyTapped)
        } label: {
            Text(applyTitle)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        // The app's accent is white, so an untinted prominent button hides its own label.
        .tint(store.color)
        .controlSize(.large)
    }

    private func failureRow(_ failure: ScanFailure) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(failure.title).font(.subheadline.weight(.semibold))
                Text(failure.message).font(.footnote).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
        }
    }

    private var limitNotice: some View {
        Text(limitText)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var messageField: some View {
        TextField(placeholder, text: $store.inputText, axis: .vertical)
            .focused($isInputFocused)
            .lineLimit(1...4)
            .font(.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24, style: .continuous))
    }

    private var sendButton: some View {
        Button {
            send(.sendTapped)
        } label: {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 16, weight: .semibold))
                .frame(height: 27)
        }
        .buttonStyle(.glass)
        .disabled(!store.canSend)
        .accessibilityLabel(sendLabel)
    }

    private var closeButton: some View {
        Button(closeTitle) {
            send(.closeTapped)
        }
    }

    /// Id of the invisible row after the last item; scrolling to it shows the newest content.
    private static let bottomID = "planChat.bottom"

    private var bottomMarker: some View {
        Color.clear
            .frame(height: 1)
            .id(Self.bottomID)
    }

    // Deferred a beat so the new row has its height before the scroll measures the content.
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(Self.bottomID, anchor: .bottom)
            }
        }
    }

    /// Sheet height as the reducer keeps it; once full it stays full while the user chats.
    private var detent: Binding<PresentationDetent> {
        Binding(
            get: { store.isExpanded ? .large : .medium },
            set: { send(.detentChanged(isExpanded: $0 == .large)) }
        )
    }

    // MARK: - Text

    private var title: String { String(localized: "Correct with AI") }
    private var greetingText: String { String(localized: "Hi! What should I correct in this workout?") }
    private var typingText: String { String(localized: "AI is writing…") }
    private var changesTitle: String { String(localized: "Changes") }
    private var applyTitle: String { String(localized: "Apply") }
    private var limitText: String { String(localized: "This chat has used up its messages. Correct the rest of the plan in the editor.") }
    private var placeholder: String { String(localized: "What should change?") }
    private var sendLabel: String { String(localized: "Send") }
    private var closeTitle: String { String(localized: "Cancel") }
}

// MARK: - Previews

#Preview("Plan chat — asking") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PlanChatView(
                store: Store(
                    initialState: PlanChatFeature.State(
                        board: ScannedBoard(boardKind: .wodDay, title: "Sets + AMRAP 13 min", activity: "crossTraining", sections: []),
                        findings: ["WOD 2: no rounds or ladder"],
                        messages: [
                            PlanChatMessage(role: .user, text: "W WOD 2 powinna być drabinka w dół 15-12-9"),
                            PlanChatMessage(role: .assistant, text: "Czyli WOD 2 to drabinka 15-12-9, na czas — zgadza się?"),
                        ]
                    )
                ) {
                    PlanChatFeature()
                }
            )
        }
}
