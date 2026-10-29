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

    // Lives inside the Activities navigation stack — no stack, title or background of its own.
    var body: some View {
        segmentContent
            .tint(store.color)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    segmentFilterMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    addMenu
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
            .fullScreenCover(
                item: $store.scope(state: \.destination?.invitationPreview, action: \.destination.invitationPreview)
            ) { previewStore in
                InvitationPreviewView(store: previewStore)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                invitationsSection
                groupsSection
            }
            .padding()
        }
    }

    @ViewBuilder
    private var invitationsSection: some View {
        if !store.pendingInvitations.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader(invitationsHeader)
                ForEach(store.pendingInvitations) { invitation in
                    invitationCard(invitation)
                }
            }
        }
    }

    @ViewBuilder
    private var groupsSection: some View {
        if !store.groups.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader(groupsHeader)
                ForEach(store.groups) { group in
                    groupCard(group)
                }
            }
        }
    }

    // MARK: - Invitation Card (structure)

    private func invitationCard(_ invitation: TeamInvitation) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                invitationTitles(invitation)
                invitationButtons(invitation)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .styledGroupBox()
    }

    // MARK: - Group Card (structure)

    private func groupCard(_ group: TeamGroup) -> some View {
        Button {
            send(.groupTapped(group))
        } label: {
            groupCardContent(group)
        }
        .buttonStyle(.plain)
    }

    private func groupCardContent(_ group: TeamGroup) -> some View {
        GroupBox {
            HStack(spacing: 12) {
                groupBadge(group)
                groupTitles(group)
                Spacer()
                chevron
            }
            .contentShape(.rect)
        }
        .styledGroupBox()
    }

    // MARK: - Implementation

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    private var segmentFilterMenu: some View {
        Menu {
            Picker(segmentPickerTitle, selection: $store.segment.sending(\.view.segmentChanged)) {
                ForEach(TeamSegment.allCases) { segment in
                    Text(segment.title)
                        .tag(segment)
                }
            }
        } label: {
            Label(segmentPickerTitle, systemImage: segmentFilterIcon)
        }
    }

    // Filled while a non-default filter is on, like the system filter buttons.
    private var segmentFilterIcon: String {
        store.segment == .private ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill"
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

    // Both ways into a group share one "+", so the bar keeps two items like the other segments.
    private var addMenu: some View {
        Menu {
            createGroupButton
            scanInviteButton
        } label: {
            Label(addTitle, systemImage: "plus")
        }
        .disabled(store.myUid == nil)
    }

    private var scanInviteButton: some View {
        Button {
            send(.scanInviteTapped)
        } label: {
            Label(scanInviteTitle, systemImage: "qrcode.viewfinder")
        }
    }

    private var createGroupButton: some View {
        Button {
            send(.createGroupTapped)
        } label: {
            Label(createGroupTitle, systemImage: "person.3")
        }
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

    private let segmentPickerTitle = String(localized: "Groups")
    private let ownGroupCaption = String(localized: "Your group")
    private let noGroupsTitle = String(localized: "No Groups Yet")
    private let noGroupsMessage = String(localized: "Create a group or scan an invite from a friend to train on the same plan and compare results.")
    private let publicTitle = String(localized: "Public Groups Coming Soon")
    private let publicMessage = String(localized: "For now, join private groups with a QR code from a friend.")
    private let failedTitle = String(localized: "Something went wrong")
    private let failedMessage = String(localized: "Unable to load your groups. Check your connection and try again.")
    private let retryTitle = String(localized: "Try Again")
    private let addTitle = String(localized: "Add")
    private let createGroupTitle = String(localized: "Create Group")
    private let scanInviteTitle = String(localized: "Scan Invite")
    private let invitationsHeader = String(localized: "Invitations")
    private let groupsHeader = String(localized: "My Groups")
    private let joinTitle = String(localized: "Join")
    private let declineTitle = String(localized: "Decline")
}
