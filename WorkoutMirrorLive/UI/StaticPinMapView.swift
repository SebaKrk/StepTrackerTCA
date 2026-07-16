//
//  StaticPinMapView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 16/07/2026.
//

import MapKit
import SwiftUI
import UIKit

/// Non-interactive map card with a single pin, backed by the imperative UIKit
/// `MKMapView` instead of SwiftUI `Map`.
///
/// Deliberately NOT SwiftUI `Map`: on iOS 26 the SwiftUI wrapper hangs the main
/// thread when mounted inside a pushed ScrollView card (VectorKit/wrapper
/// integration issues), while `MKMapView` initializes without the hitch.
struct StaticPinMapView: UIViewRepresentable {

    /// Pin location; the camera centers here.
    let coordinate: CLLocationCoordinate2D

    /// Marker title shown under the pin.
    let title: String

    /// Marker tint.
    let color: Color

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.isUserInteractionEnabled = false
        mapView.showsUserLocation = false
        mapView.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 600,
            longitudinalMeters: 600
        )

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        mapView.addAnnotation(annotation)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Static card — the pin never moves within one screen. Skipping updates
        // avoids MapKit re-render churn on unrelated SwiftUI state changes.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(markerColor: UIColor(color))
    }

    final class Coordinator: NSObject, MKMapViewDelegate {

        private let markerColor: UIColor

        init(markerColor: UIColor) {
            self.markerColor = markerColor
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            let identifier = "staticPin"
            let marker = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            marker.annotation = annotation
            marker.markerTintColor = markerColor
            return marker
        }
    }
}
