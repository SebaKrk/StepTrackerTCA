//
//  WorkoutRouteView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 16/07/2026.
//

import ComposableArchitecture
import CoreLocation
import MapKit
import SwiftUI

/// Route section of the Activity Details screen: loading card while the
/// HealthKit query runs, polyline map for routes, single pin for
/// one-coordinate workouts, nothing for indoor workouts.
struct WorkoutRouteView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<WorkoutRouteFeature>

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        if store.isLoadingLocation {
            loadingLocationView
        } else if let locations = store.routeLocations, !locations.isEmpty {
            if locations.count >= 2 {
                routeMapView(coordinates: locations.map(\.coordinate))
                    .navigationDestination(
                        item: $store.scope(state: \.routeDetails, action: \.routeDetails)
                    ) { detailsStore in
                        RouteDetailsView(store: detailsStore)
                    }
            } else {
                singleLocationMapView(coordinate: locations[0].coordinate)
            }
        }
    }

    // MARK: - Structure

    private func routeMapView(coordinates: [CLLocationCoordinate2D]) -> some View {
        GroupBox {
            routeMap(coordinates: coordinates)
                .disabled(true)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } label: {
            routeLabelButton
        }
        .styledGroupBox()
    }

    private func singleLocationMapView(coordinate: CLLocationCoordinate2D) -> some View {
        GroupBox {
            // UIKit-backed static pin — same rationale as the class-recap map:
            // SwiftUI `Map` hangs the main thread on iOS 26 in this pushed card.
            StaticPinMapView(
                coordinate: coordinate,
                title: workoutPinTitle,
                color: store.color
            )
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } label: {
            singleLocationLabel
        }
        .styledGroupBox()
    }

    private var loadingLocationView: some View {
        GroupBox {
            HStack {
                ProgressView()
                Text(loadingRouteText)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
        } label: {
            Label(localizationTitle, systemImage: "location.fill")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .styledGroupBox()
    }

    // MARK: - Implementation

    private func routeMap(coordinates: [CLLocationCoordinate2D]) -> some View {
        Map {
            MapPolyline(coordinates: coordinates)
                .stroke(store.color, lineWidth: 3)
            if let start = coordinates.first {
                Annotation(startMarkerTitle, coordinate: start) {
                    routeMarker(color: .green)
                }
            }
            if let end = coordinates.last {
                Annotation(finishMarkerTitle, coordinate: end) {
                    routeMarker(color: .red)
                }
            }
        }
    }

    private func routeMarker(color: Color) -> some View {
        Circle()
            .fill(color)
            .stroke(.white, lineWidth: 2)
            .frame(width: 16, height: 16)
    }

    private var routeLabelButton: some View {
        Button {
            store.send(.routeDetailsTapped)
        } label: {
            HStack {
                Label(routeTitle, systemImage: "figure.run")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var singleLocationLabel: some View {
        HStack {
            Label(localizationTitle, systemImage: "location.fill")
            Spacer()
            Image(systemName: "chevron.right")
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }

    private var routeTitle: String {
        String(localized: "Route", bundle: .main)
    }

    private var localizationTitle: String {
        String(localized: "Localization", bundle: .main)
    }

    private var loadingRouteText: String {
        String(localized: "Loading route...", bundle: .main)
    }

    private var startMarkerTitle: String {
        String(localized: "Start", bundle: .main)
    }

    private var finishMarkerTitle: String {
        String(localized: "Finish", bundle: .main)
    }

    private var workoutPinTitle: String {
        String(localized: "Workout", bundle: .main)
    }
}
