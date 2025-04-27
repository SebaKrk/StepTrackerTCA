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
        
        ///
        case fetchData
        
        ///
        case updateData(Result<[HKQuantitySample], Error>)
        
        ///
        case calculateMinuteHRStats
        
        ///
        case updateHRMetric([HeartRateMetricsMinute])
        //([HKQuantitySample])
        
        case calculateActiveEnergyBurned(HKWorkout)
        
        case updateActiveEnergyBurned(Double)
        
        
        // MARK: - View Actions
        
        /// View-specific actions triggered by UI events.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
    
}
