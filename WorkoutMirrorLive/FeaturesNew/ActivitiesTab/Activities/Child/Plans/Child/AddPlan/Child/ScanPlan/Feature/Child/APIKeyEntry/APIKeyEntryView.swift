//
//  APIKeyEntryView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import ComposableArchitecture
import SwiftUI

struct APIKeyEntryView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<APIKeyEntryFeature>

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                if store.hasExistingKey {
                    existingKeySection
                } else {
                    enterKeySection
                }
            }
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anuluj") {
                        store.send(.cancelTapped)
                    }
                }
            }
        }
    }

    // MARK: - Existing Key Section

    private var existingKeySection: some View {
        Section {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Klucz aktywny")
            }
            Button(role: .destructive) {
                store.send(.deleteKeyTapped)
            } label: {
                Label("Usuń klucz", systemImage: "trash")
            }
        } header: {
            Text("Anthropic API Key")
        } footer: {
            Text("Klucz jest przechowywany bezpiecznie w Keychain urządzenia.")
        }
    }

    // MARK: - Enter Key Section

    private var enterKeySection: some View {
        Section {
            SecureField("sk-ant-...", text: $store.draftKey)
                .textContentType(.password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button {
                store.send(.saveButtonTapped)
            } label: {
                Label("Zapisz", systemImage: "checkmark")
            }
            .disabled(store.draftKey.trimmingCharacters(in: .whitespaces).isEmpty)
        } header: {
            Text("Anthropic API Key")
        } footer: {
            Text("Wymagany do parsowania treningów przez Claude API. Przechowywany bezpiecznie w Keychain — nie wysyłany nigdzie poza Anthropic.")
        }
    }
}
