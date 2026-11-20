//
//  ActivitiesFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct ActivitiesFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                // MARK: - Action
                
            case let .selectedPickerChange(value):
                state.context = value
                return .none

            case .resetToRoot:
                // One tap does the first of these that applies, the way iOS
                // behaves: close what is open, then scroll back, then return to
                // the first segment. Doing them all at once would hide the
                // scrolling behind a screen that had already changed.
                if state.plans.destination != nil {
                    state.plans.destination = nil
                    return .none
                }
                if state.team.destination != nil {
                    state.team.destination = nil
                    return .none
                }
                if state.personalActivity.destination != nil {
                    state.personalActivity.destination = nil
                    return .none
                }

                switch state.context {
                case .plans where state.plans.isScrolled:
                    return .send(.plans(.scrollToTop))
                case .activity where state.personalActivity.isScrolled:
                    return .send(.personalActivity(.scrollToTop))
                default:
                    break
                }

                guard state.context != .activity else { return .none }

                return .send(.selectedPickerChange(.activity), animation: .default)

                // MARK: - Child Features
                
            case .personalActivity:
                return .none
                
            case .plans:
                return .none

            case .team:
                return .none
            }
        }
        Scope(state: \.personalActivity, action: \.personalActivity) {
            PersonalActivityFeature()
        }
        Scope(state: \.plans, action: \.plans) {
            PlansFeature()
        }
        Scope(state: \.team, action: \.team) {
            TeamFeature()
        }
    }
    
}
