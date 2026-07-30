//
//  APIKeyEntryView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: APIKeyEntryFeature.self)
struct APIKeyEntryView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<APIKeyEntryFeature>

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if store.isPresentedAsSheet {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            send(.cancelTapped)
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            }
    }

    // MARK: - Content

    private var contentView: some View {
        Form {
            if store.hasExistingKey {
                existingKeySection
                deleteSection
            } else {
                enterKeySection
            }
        }
    }

    // MARK: - Existing Key Section

    private var existingKeySection: some View {
        Section {
            HStack {
                Text("Status")
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("Active")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Anthropic API Key")
        } footer: {
            Text("The key is stored securely in the device's Keychain.")
        }
    }

    // MARK: - Delete Section

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                send(.deleteKeyTapped)
            } label: {
                HStack {
                    Spacer()
                    Label("Delete Key", systemImage: "trash")
                    Spacer()
                }
            }
        }
    }

    // MARK: - Enter Key Section

    private var enterKeySection: some View {
        Group {
            Section {
                SecureField("sk-ant-...", text: $store.draftKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Anthropic API Key")
            } footer: {
                Text("Required for workout parsing via Claude API. Stored securely in Keychain — never sent anywhere except Anthropic.")
            }

            Section {
                Button {
                    send(.saveButtonTapped)
                } label: {
                    HStack {
                        Spacer()
                        Label("Save Key", systemImage: "checkmark")
                        Spacer()
                    }
                }
                .disabled(store.draftKey.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}
