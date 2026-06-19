//
//  GymRoomRootFeature+State.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import Foundation

extension GymRoomRootFeature {

    @ObservableState
    struct State {

        /// Aktualnie wybrana sekcja w sidebar. Default `.classes` (main hub).
        var selectedItem: SidebarItem = .classes

        /// State dziecka ClassesList — orchestrates list + create + detail + liveClass.
        var classesList: ClassesListFeature.State = .init()

        /// State dziecka ClassHistory — past sessions reverse-chrono w History tab.
        /// Fetch async w `viewDidAppear` (przy każdym powrocie do tab History).
        var history: ClassHistoryFeature.State = .init()
    }

    /// Sekcje w sidebar. Subtask D rozszerzy `.history` placeholder do filtered list view.
    enum SidebarItem: String, CaseIterable, Identifiable, Sendable, Equatable {
        case classes
        case history

        public var id: String { rawValue }

        /// SF Symbol dla sidebar row icon.
        var symbol: String {
            switch self {
            case .classes: "figure.cross.training"
            case .history: "clock.arrow.circlepath"
            }
        }

        /// Localized display name dla sidebar row label.
        var title: String {
            switch self {
            case .classes: String(localized: "Classes", bundle: .main)
            case .history: String(localized: "History", bundle: .main)
            }
        }
    }
}
