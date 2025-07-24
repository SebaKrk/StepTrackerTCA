//
//  TCAFeatureAction.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/07/2025.
//

import ComposableArchitecture

/// Global protocol for structuring TCA feature actions
/// Enforces consistent action organization across all features
public protocol TCAFeatureAction {
    
    /// Actions triggered by user interactions with the view
    associatedtype ViewAction
    
    /// Actions for communicating with parent features
    associatedtype DelegateAction
    
    /// Internal actions for business logic and side effects
    associatedtype InternalAction

    /// Creates a view action
    /// - Parameter action: The view action to wrap
    /// - Returns: The wrapped action
    static func view(_: ViewAction) -> Self
    
    /// Creates a delegate action
    /// - Parameter action: The delegate action to wrap
    /// - Returns: The wrapped action
    static func delegate(_: DelegateAction) -> Self
    
    /// Creates an internal action
    /// - Parameter action: The internal action to wrap
    /// - Returns: The wrapped action
    static func internalAction(_: InternalAction) -> Self
}
