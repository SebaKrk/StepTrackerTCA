//
//  InviteView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: InviteFeature.self)
struct InviteView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<InviteFeature>

    // MARK: - Body (structure)

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        doneButton
                    }
                }
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }

    // MARK: - Content (structure)

    @ViewBuilder
    private var content: some View {
        switch store.viewState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .success:
            inviteList
        case .failed:
            failedView
        }
    }

    private var inviteList: some View {
        List {
            codeSection
            scansSection
        }
    }

    private var codeSection: some View {
        Section {
            qrCode
            replaceCodeButton
        } footer: {
            Text(codeFooter)
        }
    }

    private var scansSection: some View {
        Section {
            if store.scans.isEmpty {
                Text(noScansText)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.scans) { scan in
                    scanRow(scan)
                }
            }
        } header: {
            Text(scansHeader)
        }
    }

    // MARK: - Implementation

    @ViewBuilder
    private var qrCode: some View {
        if let image = store.qrImage {
            PlanQRCodeView(cgImage: image)
                .padding(16)
                .background(.white, in: .rect(cornerRadius: 16))
                .frame(maxWidth: 260)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
    }

    private var replaceCodeButton: some View {
        Button(role: .destructive) {
            send(.replaceCodeTapped)
        } label: {
            if store.isReplacing {
                ProgressView()
            } else {
                Text(replaceCodeTitle)
            }
        }
        .disabled(store.isReplacing)
    }

    private func scanRow(_ scan: InviteScanRow) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(scan.invitation.recipientName)
                Text(scan.invitation.scannedAt, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            statusBadge(scan.state)
        }
    }

    private func statusBadge(_ state: TeamInvitationState) -> some View {
        Text(statusTitle(state))
            .font(.caption.weight(.bold))
            .foregroundStyle(statusColor(state))
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(statusColor(state).opacity(0.15), in: .capsule)
    }

    private var doneButton: some View {
        Button {
            send(.doneTapped)
        } label: {
            Text(doneTitle)
        }
    }

    private var failedView: some View {
        ContentUnavailableView {
            Label(failedTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(failedMessage)
        }
    }

    private var codeFooter: String {
        guard let invite = store.invite else { return "" }
        return String(localized: "Show this code to someone next to you. Valid until \(invite.expiresAt.formatted(date: .abbreviated, time: .shortened)).")
    }

    private func statusTitle(_ state: TeamInvitationState) -> String {
        switch state {
        case .pending: String(localized: "Pending")
        case .accepted: String(localized: "Joined")
        case .declined: String(localized: "Declined")
        case .expired: String(localized: "Expired")
        case .revoked: String(localized: "Revoked")
        }
    }

    private func statusColor(_ state: TeamInvitationState) -> Color {
        switch state {
        case .pending: .orange
        case .accepted: .green
        case .declined: .red
        case .expired, .revoked: .secondary
        }
    }

    // MARK: - Text

    private let navigationTitle = String(localized: "Invite to Group")
    private let replaceCodeTitle = String(localized: "Revoke and Create New Code")
    private let scansHeader = String(localized: "Scanned By")
    private let noScansText = String(localized: "No one has scanned this code yet.")
    private let doneTitle = String(localized: "Done")
    private let failedTitle = String(localized: "Something went wrong")
    private let failedMessage = String(localized: "Unable to prepare the invite. Check your connection and try again.")
}
