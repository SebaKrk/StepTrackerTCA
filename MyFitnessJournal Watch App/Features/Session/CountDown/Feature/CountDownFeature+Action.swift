//
//  CountDownFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/06/2025.
//


import ComposableArchitecture

extension CountDownFeature {
    
    // MARK: - Action
    enum Action {
        
        case startCountDown
        case endCountDown
        case timerTick
        case timerFinished
        case onAppear
    }
    
}
