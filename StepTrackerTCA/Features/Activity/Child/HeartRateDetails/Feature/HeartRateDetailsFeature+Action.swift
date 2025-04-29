//
//  HeartRateDetailsFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 27/04/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit

extension HeartRateDetailsFeature {
    
    // MARK: - Action
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        /// Action triggered when the user selects a date on the chart.
        case selectedChartMinChange(Date?)
        
        // MARK: - Actions
        
        /// Initiates the process of fetching heart rate data from HealthKit.
        case fetchData

        /// Updates the state with the result of fetching heart rate samples.
        case updateData(Result<[HKQuantitySample], Error>)

        /// Calculates heart rate statistics per minute based on the fetched data.
        case calculateMinuteHRStats

        /// Updates the heart rate metrics per minute used for charting and analysis.
        case updateHRMetric([HeartRateMetricsMinute])

        /// Calculates the amount of active energy burned from a workout sample.
        case calculateActiveEnergyBurned(HKWorkout)
        
        /// Updates the active energy burned value after calculating it from the workout data.
        case updateActiveEnergyBurned(Double)
        
        /// Action triggered when the user selects a date on the step chart.
        case selectedChartDateChange(Date?)
        
        
        // MARK: - View Actions
        
        /// View-specific actions triggered by UI events.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
    
}
