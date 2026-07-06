//
//  ClassHistoryDetailFeature+Action.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 22/06/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension ClassHistoryDetailFeature {

    @CasePathable
    enum Action: ViewAction, BindableAction {

        /// Bindings dla Picker'a chartViewMode (SegmentedControl).
        case binding(BindingAction<State>)

        /// Internal — result of async fetch + decode + pre-aggregation. Second field:
        /// per-minute range bars; third: gap-aware line segments for the combined
        /// chart — both pre-computed off the main thread (no compute in View body).
        case athletesLoaded([AthleteSummary], [UUID: [HRMinuteRange]], [UUID: [AthleteSummary.HRSegment]])

        /// `gymClassClient.fetchAthletesForSession` rzucił błąd — `viewState = .failed`,
        /// View pokazuje retry placeholder zamiast pustego widoku.
        case fetchFailed

        /// User scrubował/tapnął wykres karty `athleteID`. `nil` = scrub-out
        /// (Charts wysyła nil gdy user puszcza palec poza obszar chart'u).
        case minuteSelected(athleteID: UUID, Date?)

        /// User scrubował combined LineMark chart. Charts wysyła Date z dokładnością
        /// ms; View helper mapuje na najbliższy sample każdego athlety. `nil` = scrub-out.
        case combinedTimeSelected(Date?)

        case delegate(Delegate)
        case alert(PresentationAction<Alert>)
        case view(View)

        enum Delegate: Equatable {
            /// User skasował sesję z menu w detail → parent ClassHistory pop'uje detail
            /// + remove ze state.sessions. Parent jest source of truth dla list.
            case sessionDeleted(UUID)
        }

        enum Alert: Equatable {
            /// Trener potwierdził cascade delete sesji + athlete data.
            case confirmDelete
        }

        enum View {
            /// Lifecycle — fetch athletes na pojawienie się detail. `.task` w View.
            case viewDidAppear

            /// Ellipsis menu → "Usuń" — present alert confirm.
            case deleteTapped
        }
    }
}
