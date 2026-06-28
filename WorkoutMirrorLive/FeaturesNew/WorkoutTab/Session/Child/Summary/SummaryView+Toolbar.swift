//
//  SummaryView+Toolbar.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/06/2026.
//
//  Toolbar items dla SummaryView — cancel (manual entry only), discard (happy path only), save.
//  Wydzielony z monolithic SummaryView.swift w IOS-00096-D.

import ComposableArchitecture
import SwiftUI

extension SummaryView {

    // MARK: - Toolbar

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        if store.isManualEntry {
            // Manual entry mode (z History): cancel = wyjdź bez zapisu, workout nietknięty.
            // Brak Discard — kasowanie HKWorkout to data loss (workout istnieje od dawna).
            ToolbarItem(placement: .topBarLeading) {
                cancelButton
            }
        }
        ToolbarItemGroup(placement: .bottomBar) {
            if !store.isManualEntry {
                discardButton
            }
            Spacer()
            saveButton
        }
    }

    // MARK: - Buttons

    private var cancelButton: some View {
        Button {
            send(.closeButtonTapped)
        } label: {
            Text(String(localized: "Anuluj"))
        }
    }

    private var discardButton: some View {
        Button {
            send(.discardWorkoutButtonTapped)
        } label: {
            if store.isDiscarding {
                ProgressView()
                    .controlSize(.small)
                    .tint(.red)
            } else {
                Text(String(localized: "Discard"))
                    .foregroundStyle(.red)
            }
        }
        .disabled(store.isDiscarding)
    }

    private var saveButton: some View {
        Button {
            send(.endWorkoutButtonTapped)
        } label: {
            Text(String(localized: "Save"))
                .fontWeight(.semibold)
        }
    }
}
