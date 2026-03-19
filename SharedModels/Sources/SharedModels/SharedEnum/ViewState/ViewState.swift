//
//  ViewState.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import Foundation

public enum ViewState: Equatable {
    
    /// The state in which the view reads the relevant information necessary for it to function correctly.
    case loading
    
    /// The state when the view is correctly loaded and displays the relevant content.
    case success
    
    /// Error has occurred when loading the view.
    case failed
}
