//
//  PersonProfileEditView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/03/2026.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: PersonProfileEditFeature.self)
struct PersonProfileEditView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<PersonProfileEditFeature>

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                contactSection
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelButton
                saveButton
            }
        }
    }

    // MARK: - SubView

    private var profileSection: some View {
        Section {
            nameField
            surnameField
            nicknameField
        } header: {
            Text("Profile")
        }
    }

    private var contactSection: some View {
        Section {
            emailField
        } header: {
            Text("Contact")
        }
    }

    private var nameField: some View {
        TextField("Name", text: $store.name)
    }

    private var surnameField: some View {
        TextField("Surname", text: $store.surname)
    }

    private var nicknameField: some View {
        TextField("Nickname", text: $store.nickname)
    }

    private var emailField: some View {
        TextField("Email", text: $store.email)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                send(.cancelButtonTapped)
            } label: {
                Text("Cancel")
            }
        }
    }

    @ToolbarContentBuilder
    private var saveButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.saveButtonTapped)
            } label: {
                Text("Save")
                    .bold()
            }
        }
    }

}
