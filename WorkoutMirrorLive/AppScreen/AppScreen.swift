//
//  AppScreen.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 29/07/2025.
//

import SwiftUI

/// Enum representing the available screens (tabs) in the application.
///
/// Each case corresponds to a specific tab, with its own unique functionality and purpose.
/// to enable seamless usage in SwiftUI and navigation systems.
enum AppScreen: Codable, Hashable, Identifiable, CaseIterable {
    
    case live
    
    case workout
    
    case person
    
    var id: Self { self }
    
}

extension AppScreen {
    
    @ViewBuilder
    var label: some View {
        switch self {
        case .live:
            Label(
                String(localized: "Live",
                       comment: "The Live Tab displays real-time heart rate and workout data."),
                systemImage: "figure"//"waveform.path.ecg"
            )
            
        case .workout:
            Label(
                String(localized: "Workout",
                       comment: "The Workout Tab lets users review or start workouts."),
                systemImage: "figure.run"
            )
            
        case .person:
            Label(
                String(localized: "Profile",
                       comment: "The Profile Tab contains user info, connected sensors, and settings."),
                systemImage: "person.fill"
            )
        }
    }
    
    var title: String {
        switch self {
        case .live: return "Live"
        case .workout: return "Workout"
        case .person: return "Profile"
        }
    }
    
    var image: String {
        switch self {
        case .live: return "figure"//"waveform.path.ecg"
        case .workout: return "figure.run"
        case .person: return "person.fill"
        }
    }
}



//zakladaka perosn:
//•    ustawienia sensorów / BLE
//•    dane użytkownika (wiek, płeć, waga…)
//•    prywatność / HealthKit
//•    eksport danych
//•    dane kontaktowe / feedback
