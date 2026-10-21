//
//  SearchToolbarModifier.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 21/10/2026.
//

import SwiftUI

/// Navigation bar search: a magnifier that opens into a field, with a close button beside it.
struct SearchToolbarModifier: ViewModifier {

    let title: String
    @Binding var phrase: String
    @Binding var isSearching: Bool
    let prompt: String

    // Focus is the only way to raise the keyboard when the magnifier opens the field.
    @FocusState private var isFieldFocused: Bool

    func body(content: Content) -> some View {
        content
            .navigationTitle(isSearching ? "" : title)
            .toolbar {
                ToolbarItem(id: searchSlot, placement: .automatic) {
                    searchFieldOrMagnifier
                }
                if isSearching {
                    ToolbarSpacer()
                    ToolbarItem(id: closeSlot, placement: .automatic) {
                        closeButton
                    }
                }
            }
    }

    // MARK: - Actions

    private func searchOpened() {
        withAnimation { isSearching = true }
        isFieldFocused = true
    }

    private func searchClosed() {
        isFieldFocused = false
        withAnimation { isSearching = false }
    }

    // MARK: - Search

    @ViewBuilder
    private var searchFieldOrMagnifier: some View {
        if isSearching {
            searchField
        } else {
            magnifierButton
        }
    }

    private var searchField: some View {
        TextField(prompt, text: $phrase)
            .focused($isFieldFocused)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .frame(maxWidth: fieldWidth)
            .padding(.leading)
    }

    private var magnifierButton: some View {
        Button {
            searchOpened()
        } label: {
            Label(searchTitle, systemImage: searchSymbol)
        }
    }

    private var closeButton: some View {
        Button {
            searchClosed()
        } label: {
            Label(closeTitle, systemImage: closeSymbol)
        }
    }

    // MARK: - Measurements

    private var fieldWidth: CGFloat { 400 }

    // MARK: - Slots

    private var searchSlot: String { "search" }

    private var closeSlot: String { "close" }

    // MARK: - Text

    private var searchTitle: String {
        String(localized: "Search", bundle: .main)
    }

    private var closeTitle: String {
        String(localized: "Close", bundle: .main)
    }

    // MARK: - Symbols

    private var searchSymbol: String { "magnifyingglass" }

    private var closeSymbol: String { "xmark" }
}
