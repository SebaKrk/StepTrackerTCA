//
//  DeviceOption.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/08/2025.
//

import Foundation

enum DeviceOption: CaseIterable, Equatable {
    
    case watch
    case iphone
    case mirror
    
    var title: String {
        switch self {
        case .watch:  "Watch"
        case .iphone: "iPhone"
        case .mirror: "Mirror"
        }
    }
    
    var symbolName: String {
        switch self {
        case .watch:  "applewatch"
        case .iphone: "iphone"
        case .mirror: "rectangle.on.rectangle"
        }
    }
    
}
