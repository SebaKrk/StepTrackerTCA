//
//  CreateGroupView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: CreateGroupFeature.self)
struct CreateGroupView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<CreateGroupFeature>

    // MARK: - Body (structure)

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                identitySection
                errorSection
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    cancelButton
                }
                ToolbarItem(placement: .confirmationAction) {
                    createButton
                }
            }
        }
        .interactiveDismissDisabled(store.isSaving)
    }

    // MARK: - Sections (structure)

    private var nameSection: some View {
        Section {
            nameField
        } footer: {
            Text(nameHint)
        }
    }

    private var identitySection: some View {
        Section {
            LabeledContent(identityTitle, value: store.displayName)
        } footer: {
            Text(identityHint)
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let message = store.errorMessage {
            Section {
                Text(message)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Implementation

    private var nameField: some View {
        TextField(namePrompt, text: $store.name.sending(\.view.nameChanged))
            .textInputAutocapitalization(.words)
            .submitLabel(.done)
            .disabled(store.isSaving)
    }

    private var cancelButton: some View {
        Button {
            send(.cancelTapped)
        } label: {
            Text(cancelTitle)
        }
        .disabled(store.isSaving)
    }

    @ViewBuilder
    private var createButton: some View {
        if store.isSaving {
            ProgressView()
        } else {
            Button {
                send(.createTapped)
            } label: {
                Text(createTitle)
            }
            .disabled(!store.isCreateEnabled)
        }
    }

    // MARK: - Text

    private let navigationTitle = String(localized: "New Group")
    private let namePrompt = String(localized: "Group name")
    private let nameHint = String(localized: "3–40 characters. The group is private — people join only with your QR code.")
    private let identityTitle = String(localized: "Others see you as")
    private let identityHint = String(localized: "Taken from your profile: nickname, then first name.")
    private let cancelTitle = String(localized: "Cancel")
    private let createTitle = String(localized: "Create")
}
