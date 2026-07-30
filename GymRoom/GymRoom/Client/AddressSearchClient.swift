//
//  AddressSearchClient.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 15/07/2026.
//

import ComposableArchitecture
import Foundation
import MapKit

// MARK: - Domain models

/// One autocomplete row from MapKit while the trainer types an address.
/// `id` is the visible text — stable enough to diff the suggestion list and to
/// re-resolve on tap (MapKit's `MKLocalSearchCompletion` is not `Sendable`, so we
/// carry plain strings across the dependency boundary instead of the raw object).
struct AddressSuggestion: Identifiable, Equatable, Sendable {
    let title: String       // e.g. "Iron Den"
    let subtitle: String    // e.g. "ul. Przykładowa 1, Warszawa"

    var id: String { title + "\n" + subtitle }

    /// Human-readable single line for display / persistence in `location`.
    var displayAddress: String {
        subtitle.isEmpty ? title : "\(title), \(subtitle)"
    }
}

/// A suggestion resolved to real coordinates via `MKLocalSearch`.
struct ResolvedAddress: Equatable, Sendable {
    let address: String
    let latitude: Double
    let longitude: Double
}

enum AddressSearchError: Error, Equatable {
    case noResults
}

// MARK: - Client

/// TCA dependency boundary over MapKit address search. Same struct-of-closures
/// pattern as `GymClassClient`: `private enum …Key: DependencyKey`, no macro.
///
/// - `suggestions(query)` streams autocomplete rows as the user types (one live
///   `MKLocalSearchCompleter` per subscription; cancelling the effect tears it down).
/// - `resolve(suggestion)` turns a tapped row into coordinates via `MKLocalSearch`.
struct AddressSearchClient: Sendable {
    var suggestions: @Sendable (_ query: String) -> AsyncStream<[AddressSuggestion]> = { _ in
        AsyncStream { $0.finish() }
    }
    var resolve: @Sendable (_ suggestion: AddressSuggestion) async throws -> ResolvedAddress
}

// MARK: - DependencyValues

extension DependencyValues {
    var addressSearchClient: AddressSearchClient {
        get { self[AddressSearchClientKey.self] }
        set { self[AddressSearchClientKey.self] = newValue }
    }
}

// MARK: - DependencyKey

private enum AddressSearchClientKey: DependencyKey {

    static let liveValue = AddressSearchClient(
        suggestions: { query in
            AsyncStream { continuation in
                // The completer + delegate must stay alive for the whole stream;
                // `MKLocalSearchCompleter.delegate` is weak, so the box (held by the
                // task) is what keeps them retained until the stream is torn down.
                let task = Task { @MainActor in
                    let box = AddressCompleterBox(continuation: continuation)
                    box.update(query: query)
                    // Park so `box` stays referenced; cancellation releases it.
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(60))
                    }
                    box.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        },
        resolve: { suggestion in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = suggestion.displayAddress
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else {
                throw AddressSearchError.noResults
            }
            let coordinate = item.placemark.coordinate
            return ResolvedAddress(
                address: suggestion.displayAddress,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        }
    )

    // Deterministic default for tests/previews: no network, empty stream, and a
    // fixed resolved coordinate so reducers can assert without hitting MapKit.
    static let testValue = AddressSearchClient(
        resolve: { suggestion in
            ResolvedAddress(address: suggestion.displayAddress, latitude: 0, longitude: 0)
        }
    )
}

// MARK: - Completer box (MainActor)

/// Retains an `MKLocalSearchCompleter` and bridges its delegate callbacks into an
/// `AsyncStream`. MainActor-isolated because MapKit's completer is main-thread only.
@MainActor
private final class AddressCompleterBox: NSObject, MKLocalSearchCompleterDelegate {

    private let completer = MKLocalSearchCompleter()
    private let continuation: AsyncStream<[AddressSuggestion]>.Continuation

    init(continuation: AsyncStream<[AddressSuggestion]>.Continuation) {
        self.continuation = continuation
        super.init()
        completer.resultTypes = .address
        completer.delegate = self
    }

    func update(query: String) {
        completer.queryFragment = query
    }

    func finish() {
        completer.delegate = nil
        continuation.finish()
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results.map {
            AddressSuggestion(title: $0.title, subtitle: $0.subtitle)
        }
        continuation.yield(results)
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        continuation.yield([])
    }
}
