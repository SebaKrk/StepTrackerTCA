//
//  AppScreen.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/01/2025.
//

import SwiftUI

/// Enum representing the available screens (tabs) in the application.
///
/// Each case corresponds to a specific tab, with its own unique functionality and purpose.
/// to enable seamless usage in SwiftUI and navigation systems.
enum AppScreen: Codable, Hashable, Identifiable, CaseIterable {
    
    case summary
    case workout
    case fuel
    case community
    case settings
    case personData
    
    var id: Self { self }
    
}

extension AppScreen {
    
    @ViewBuilder
    var label: some View {
        switch self {
        case .summary:
            Label(
                String(localized: "Dashboard",
                       comment: "The Dashboard Tab presents an overview of key metrics and activities."),
                systemImage: "heart.fill"
            )
        case .workout:
            Label(
                String(localized: "Workout",
                       comment: "The Workout Tab provides access to timers and activity tracking."),
                systemImage: "figure.run"
            )
        case .fuel:
            Label(
                String(localized: "Fuel",
                       comment: "The Fuel Tab focuses on diet and nutritional information."),
                systemImage: "pencil.and.list.clipboard"
            )
        case .community:
            Label(
                String(localized: "Community",
                       comment: "The Community Tab connects users for sharing and interaction."),
                systemImage: "person.3"
            )
            
        case .settings:
            Label(
                String(localized: "settings",
                       comment: "The More Tab provides access to additional options and settings."),
                systemImage: "gearshape"
            )
        case .personData:
            Label(
                String(localized: "Personal Data",
                       comment: "The Personal Data Tab allows users to view and edit their personal information."),
                systemImage: "person"
            )
        }
    }
    
}
