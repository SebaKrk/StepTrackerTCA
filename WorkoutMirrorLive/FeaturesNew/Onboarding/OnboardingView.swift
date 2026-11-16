//
//  OnboardingView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: OnboardingFeature.self)
struct OnboardingView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<OnboardingFeature>

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                continueSection
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(true)
    }

    // MARK: - SubView

    private var identitySection: some View {
        Section {
            nameField
            surnameField
            nicknameField
        } footer: {
            Text(identityFooterText)
        }
    }

    private var continueSection: some View {
        Section {
            continueButton
        }
    }

    private var nameField: some View {
        TextField(namePlaceholder, text: $store.name)
            .textContentType(.givenName)
            .autocorrectionDisabled()
    }

    private var surnameField: some View {
        TextField(surnamePlaceholder, text: $store.surname)
            .textContentType(.familyName)
            .autocorrectionDisabled()
    }

    private var nicknameField: some View {
        TextField(nicknamePlaceholder, text: $store.nickname)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
    }

    private var continueButton: some View {
        Button {
            send(.continueTapped)
        } label: {
            HStack {
                Spacer()
                Text(continueTitle)
                Spacer()
            }
            .overlay(alignment: .trailing) {
                if store.isSaving {
                    ProgressView()
                }
            }
        }
        .disabled(!store.canContinue)
    }

    // MARK: - Text

    private var title: String {
        String(localized: "How should others see you?")
    }

    /// Not the existing "Name" key — that one is already translated as the name
    /// of a thing, which reads as nonsense next to a surname.
    private var namePlaceholder: String {
        String(localized: "First name")
    }

    private var surnamePlaceholder: String {
        String(localized: "Surname (optional)")
    }

    private var nicknamePlaceholder: String {
        String(localized: "Nickname")
    }

    private var continueTitle: String {
        String(localized: "Let's start")
    }

    /// Says where each field ends up, because one of them is shown to strangers
    /// and the other two never leave the phone.
    private var identityFooterText: String {
        String(localized: "People in your groups and the coach in the gym see your nickname. Your name and surname stay on this device.")
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }
    )
}
