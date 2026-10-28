//
//  TeamView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: TeamFeature.self)
struct TeamView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<TeamFeature>

    // MARK: - Body (structure)

    var body: some View {
        NavigationStack {
            segmentContent
                .safeAreaBar(edge: .top) {
                    segmentPicker
                }
                .background(backgroundGradient)
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        scanInviteButton
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        createGroupButton
                    }
                }
                .sheet(
                    item: $store.scope(state: \.destination?.createGroup, action: \.destination.createGroup)
                ) { createGroupStore in
                    CreateGroupView(store: createGroupStore)
                        .presentationDetents([.medium])
                }
                .navigationDestination(
                    item: $store.scope(state: \.destination?.group, action: \.destination.group)
                ) { groupStore in
                    GroupView(store: groupStore)
                }
                .sheet(
                    item: $store.scope(state: \.destination?.invitationPreview, action: \.destination.invitationPreview)
                ) { previewStore in
                    InvitationPreviewView(store: previewStore)
                }
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }

    // MARK: - Segments (structure)

    @ViewBuilder
    private var segmentContent: some View {
        switch store.segment {
        case .private:
            privateContent
        case .public:
            publicGroupsComingSoonView
        }
    }

    @ViewBuilder
    private var privateContent: some View {
        switch store.viewState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .success:
            groupsListOrEmpty
        case .failed:
            failedView
        }
    }

    @ViewBuilder
    private var groupsListOrEmpty: some View {
        if store.groups.isEmpty && store.pendingInvitations.isEmpty {
            noGroupsView
        } else {
            groupsList
        }
    }

    private var groupsList: some View {
        List {
            invitationsSection
            groupsSection
        }
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var invitationsSection: some View {
        if !store.pendingInvitations.isEmpty {
            Section {
                ForEach(store.pendingInvitations) { invitation in
                    invitationRow(invitation)
                }
            } header: {
                Text(invitationsHeader)
            }
        }
    }

    @ViewBuilder
    private var groupsSection: some View {
        if !store.groups.isEmpty {
            Section {
                ForEach(store.groups) { group in
                    groupRow(group)
                }
            } header: {
                Text(groupsHeader)
            }
        }
    }

    // MARK: - Invitation Row (structure)

    private func invitationRow(_ invitation: TeamInvitation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            invitationTitles(invitation)
            invitationButtons(invitation)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Group Row (structure)

    private func groupRow(_ group: TeamGroup) -> some View {
        Button {
            send(.groupTapped(group))
        } label: {
            groupRowContent(group)
        }
        .buttonStyle(.plain)
    }

    private func groupRowContent(_ group: TeamGroup) -> some View {
        HStack(spacing: 12) {
            groupBadge(group)
            groupTitles(group)
            Spacer()
            chevron
        }
        .padding(.vertical, 6)
        .contentShape(.rect)
    }

    // MARK: - Implementation

    private var segmentPicker: some View {
        Picker(segmentPickerTitle, selection: $store.segment.sending(\.view.segmentChanged)) {
            ForEach(TeamSegment.allCases) { segment in
                Text(segment.title)
                    .tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .padding([.leading, .trailing], 6)
        .padding(.bottom, 12)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [store.color.opacity(0.25), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func groupBadge(_ group: TeamGroup) -> some View {
        Text(group.name.prefix(2).uppercased())
            .font(.subheadline.weight(.heavy))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(store.color.gradient, in: .rect(cornerRadius: 12))
    }

    private func groupTitles(_ group: TeamGroup) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(group.name)
                .font(.headline)
            if group.ownerUid == store.myUid {
                Text(ownGroupCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func invitationTitles(_ invitation: TeamInvitation) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(invitation.invite.groupName)
                .font(.headline)
            Text(String(localized: "From \(invitation.invite.createdByName)"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func invitationButtons(_ invitation: TeamInvitation) -> some View {
        HStack(spacing: 10) {
            declineInvitationButton(invitation)
            joinInvitationButton(invitation)
        }
        .disabled(store.respondingInvitationIds.contains(invitation.id))
    }

    private func joinInvitationButton(_ invitation: TeamInvitation) -> some View {
        Button {
            send(.invitationJoinTapped(invitation))
        } label: {
            Text(joinTitle)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    private func declineInvitationButton(_ invitation: TeamInvitation) -> some View {
        Button(role: .destructive) {
            send(.invitationDeclineTapped(invitation))
        } label: {
            Text(declineTitle)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.tertiary)
    }

    private var noGroupsView: some View {
        ContentUnavailableView {
            Label(noGroupsTitle, systemImage: "person.3")
        } description: {
            Text(noGroupsMessage)
        } actions: {
            emptyCreateGroupButton
        }
    }

    private var scanInviteButton: some View {
        Button {
            send(.scanInviteTapped)
        } label: {
            Label(scanInviteTitle, systemImage: "qrcode.viewfinder")
        }
        .disabled(store.myUid == nil)
    }

    private var createGroupButton: some View {
        Button {
            send(.createGroupTapped)
        } label: {
            Label(createGroupTitle, systemImage: "plus")
        }
        .disabled(store.myUid == nil)
    }

    private var emptyCreateGroupButton: some View {
        Button {
            send(.createGroupTapped)
        } label: {
            Label(createGroupTitle, systemImage: "plus")
        }
    }

    private var publicGroupsComingSoonView: some View {
        ContentUnavailableView {
            Label(publicTitle, systemImage: "globe")
        } description: {
            Text(publicMessage)
        }
    }

    private var failedView: some View {
        ContentUnavailableView {
            Label(failedTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(failedMessage)
        } actions: {
            retryButton
        }
    }

    private var retryButton: some View {
        Button {
            send(.retryTapped)
        } label: {
            Text(retryTitle)
        }
    }

    // MARK: - Text

    private let navigationTitle = String(localized: "Team")
    private let segmentPickerTitle = String(localized: "Team segment")
    private let ownGroupCaption = String(localized: "Your group")
    private let noGroupsTitle = String(localized: "No Groups Yet")
    private let noGroupsMessage = String(localized: "Create a group or scan an invite from a friend to train on the same plan and compare results.")
    private let publicTitle = String(localized: "Public Groups Coming Soon")
    private let publicMessage = String(localized: "For now, join private groups with a QR code from a friend.")
    private let failedTitle = String(localized: "Something went wrong")
    private let failedMessage = String(localized: "Unable to load your groups. Check your connection and try again.")
    private let retryTitle = String(localized: "Try Again")
    private let createGroupTitle = String(localized: "Create Group")
    private let scanInviteTitle = String(localized: "Scan Invite")
    private let invitationsHeader = String(localized: "Invitations")
    private let groupsHeader = String(localized: "My Groups")
    private let joinTitle = String(localized: "Join")
    private let declineTitle = String(localized: "Decline")
}
