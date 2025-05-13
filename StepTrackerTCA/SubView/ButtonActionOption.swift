//
//  ButtonActionOption.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/05/2025.
//

import Foundation

protocol ButtonActionOption: CaseIterable, Hashable where AllCases: RandomAccessCollection {
    
    var name: String { get }
    var icon: String { get }
    var actionDescription: String { get }
    
}
