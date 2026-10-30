//
//  ManageGroupView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: ManageGroupFeature.self)
struct ManageGroupView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ManageGroupFeature>

    // MARK: - Body (structure)

    // Cards inside a plain List, like the activity list: the member cards get native swipe actions.
    var body: some View {
        List {
            Group {
                sectionHeader(nameHeader)
                nameCard
                sectionHeader(membersHeader)
                    .padding(.top, 8)
                membersContent
                cardFooter(membersHint)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(backgroundGradient)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                editOrSaveButton
            }
        }
        .safeAreaInset(edge: .bottom) {
            if store.isEditingName {
                deleteBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: store.isEditingName)
        .alert($store.scope(state: \.alert, action: \.alert))
        .disabled(store.isWorking)
        .onAppear {
            send(.viewDidAppear)
        }
    }

    // MARK: - Cards (structure)

    // Read-only until "Edit"; then the field opens with its rule underneath.
    private var nameCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                if store.isEditingName {
                    nameField
                    cardFooter(nameHint)
                } else {
                    nameText
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .styledGroupBox()
    }

    // Only in edit mode: the destructive action with its consequence spelled out above it.
    private var deleteBar: some View {
        VStack(spacing: 8) {
            cardFooter(deleteHint)
                .multilineTextAlignment(.center)
            deleteGroupButton
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var membersContent: some View {
        switch store.viewState {
        case .loading:
            loadingCard
        case .success:
            ForEach(store.members) { member in
                memberCard(member)
            }
        case .failed:
            failedCard
        }
    }

    // MARK: - Member Card (structure)

    // One card per member; the owner's own card has no swipe actions.
    private func memberCard(_ member: TeamMember) -> some View {
        GroupBox {
            HStack(spacing: 12) {
                memberInitials(member)
                memberTitles(member)
                Spacer(minLength: 0)
                if member.uid == store.myUid {
                    ownerBadge
                } else if store.workingMemberUid == member.uid {
                    memberSpinner
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .styledGroupBox()
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if member.uid != store.myUid {
                removeButton(member)
                transferButton(member)
            }
        }
    }

    private var loadingCard: some View {
        GroupBox {
            ProgressView()
                .frame(maxWidth: .infinity)
        }
        .styledGroupBox()
    }

    private var failedCard: some View {
        GroupBox {
            failedView
        }
        .styledGroupBox()
    }

    // MARK: - Implementation

    private var nameText: some View {
        Text(store.group.name)
            .font(.body)
            .foregroundStyle(.primary)
    }

    private var nameField: some View {
        TextField(nameHeader, text: $store.name)
            .textInputAutocapitalization(.words)
            .submitLabel(.done)
            .onSubmit { send(.saveNameTapped) }
            .font(.body)
            .foregroundStyle(.primary)
    }

    private var editOrSaveButton: some View {
        Button {
            send(store.isEditingName ? .saveNameTapped : .editTapped, animation: .snappy)
        } label: {
            if store.working == .rename {
                ProgressView()
            } else {
                Text(store.isEditingName ? saveTitle : editTitle)
                    .fontWeight(store.isEditingName ? .semibold : .regular)
            }
        }
    }

    private func memberInitials(_ member: TeamMember) -> some View {
        Text(member.displayName.prefix(2).uppercased())
            .font(.caption.weight(.bold))
            .frame(width: 34, height: 34)
            .background(.fill.tertiary, in: .circle)
    }

    private func memberTitles(_ member: TeamMember) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(member.displayName)
                .font(.body)
                .foregroundStyle(.primary)
            Text(String(localized: "Joined \(member.joinedAt.formatted(.dateTime.day().month()))"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // Same footprint as the owner badge's row height, so the card does not jump while the change is in flight.
    private var memberSpinner: some View {
        ProgressView()
            .frame(width: 44, height: 34)
    }

    private var ownerBadge: some View {
        Text(youOwnerLabel)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func transferButton(_ member: TeamMember) -> some View {
        Button {
            send(.transferTapped(member))
        } label: {
            Label(transferTitle, systemImage: "person.badge.key")
        }
        .tint(.indigo)
    }

    private func removeButton(_ member: TeamMember) -> some View {
        Button {
            send(.removeTapped(member))
        } label: {
            Label(removeTitle, systemImage: "person.badge.minus")
        }
        .tint(.red)
    }

    private var deleteGroupButton: some View {
        Button(role: .destructive) {
            send(.deleteGroupTapped)
        } label: {
            Group {
                if store.working == .delete {
                    ProgressView()
                } else {
                    Label(deleteTitle, systemImage: "trash")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .tint(.red)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    private func cardFooter(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
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

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [store.color.opacity(0.25), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Text

    private let navigationTitle = String(localized: "Manage Group")
    private let nameHeader = String(localized: "Group name")
    private let nameHint = String(localized: "3–40 characters. Every member sees the new name.")
    private let saveTitle = String(localized: "Save")
    private let editTitle = String(localized: "Edit")
    private let membersHeader = String(localized: "Members")
    private let membersHint = String(localized: "Swipe a member left to transfer ownership or remove them.")
    private let youOwnerLabel = String(localized: "You · Owner")
    private let transferTitle = String(localized: "Transfer")
    private let removeTitle = String(localized: "Remove")
    private let deleteTitle = String(localized: "Delete Group")
    private let deleteHint = String(localized: "It disappears for everyone with its plans and results. Plan copies in members' Plans stay.")
    private let failedTitle = String(localized: "Something went wrong")
    private let failedMessage = String(localized: "Unable to load the group members. Check your connection and try again.")
    private let retryTitle = String(localized: "Try Again")
}
