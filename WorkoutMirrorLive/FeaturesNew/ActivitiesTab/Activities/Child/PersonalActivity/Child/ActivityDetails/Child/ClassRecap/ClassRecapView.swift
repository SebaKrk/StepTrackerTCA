//
//  ClassRecapView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 16/07/2026.
//

import ComposableArchitecture
import CoreLocation
import SharedModels
import SwiftUI

/// "Group class" recap section: class name, place in the ranking, class points
/// in one line, with the gym-location map below (three states: loading /
/// ready / unavailable). Hidden entirely when the workout wasn't part of a
/// GymRoom class.
struct ClassRecapView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ClassRecapFeature>

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        if let recap = store.classParticipation {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    recapInfo(recap)
                    recapMap
                }
                // Większy odstęp pod tytułem niż domyślny GroupBox (życzenie usera —
                // tylko ta sekcja, reszta kart używa standardowego labelu).
                .padding(.top, 8)
            } label: {
                recapHeader
            }
            .styledGroupBox()
        }
    }

    // MARK: - Structure

    /// Own header for the recap section — white title (`.primary`) instead of the
    /// shared card label's secondary grey. Scoped to this section by user request.
    private var recapHeader: some View {
        Label(recapTitle, systemImage: "person.2.fill")
            .font(.caption)
            .foregroundStyle(.primary)
    }

    /// One-line summary in the zone-row style (label `.caption`, value `.caption.bold`):
    /// "Name: CrossFit   Athlete: 1/1   Points in class: ⚡ 231 pkt".
    private func recapInfo(_ recap: ClassParticipation) -> some View {
        HStack(spacing: 16) {
            recapStat(label: nameLabel, value: recap.gymName)
            recapStat(label: athleteLabel, value: "\(recap.place)/\(recap.participantCount)")
            classPointsStat(recap.classPoints)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Map with three states. Mounts as its own step (parent's `mountMap` command
    /// after every load settled), so entering the tab is never held up.
    @ViewBuilder
    private var recapMap: some View {
        switch store.classMapState {
        case .loading:
            recapMapLoading
        case .ready:
            recapMapView
        case .unavailable:
            recapMapUnavailable
        }
    }

    // MARK: - Implementation

    private func recapStat(label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label + ":")
                .font(.caption)
                .foregroundStyle(.primary)
            Text(value)
                .font(.caption)
                .bold()
        }
    }

    private func classPointsStat(_ points: Int) -> some View {
        HStack(spacing: 4) {
            Text(classPointsLabel + ":")
                .font(.caption)
                .foregroundStyle(.primary)
            Image(systemName: "bolt.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
            Text("\(points) " + pointsUnit)
                .font(.caption)
                .bold()
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private var recapMapView: some View {
        if let recap = store.classParticipation,
           let latitude = recap.latitude, let longitude = recap.longitude {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            // UIKit `MKMapView` (StaticPinMapView), not SwiftUI `Map` — the SwiftUI
            // wrapper hangs the main thread on iOS 26 when mounted in this pushed
            // ScrollView card; the imperative view initializes without the hitch.
            StaticPinMapView(coordinate: coordinate, title: recap.gymName, color: store.color)
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var recapMapLoading: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .frame(height: 150)
    }

    private var recapMapUnavailable: some View {
        ContentUnavailableView(mapUnavailableText, systemImage: "mappin.slash")
            .frame(height: 150)
    }

    private var recapTitle: String {
        String(localized: "Group class", bundle: .main)
    }

    private var nameLabel: String {
        String(localized: "Name", bundle: .main)
    }

    private var athleteLabel: String {
        String(localized: "Score", bundle: .main)
    }

    private var classPointsLabel: String {
        String(localized: "Points in class", bundle: .main)
    }

    private var pointsUnit: String {
        String(localized: "pkt", bundle: .main)
    }

    private var mapUnavailableText: String {
        String(localized: "No location", bundle: .main)
    }
}
