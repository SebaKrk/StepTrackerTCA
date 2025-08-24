//
//  DeviceOption.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/08/2025.
//

import Foundation

enum DeviceOption: CaseIterable, Equatable {
    
    case iphone
    case watch
    case mirror
    
    var title: String {
        switch self {
        case .iphone: "iPhone"
        case .watch:  "Watch"
        case .mirror: "Mirror"
        }
    }
    
    var symbolName: String {
        switch self {
        case .iphone: "iphone"
        case .watch:  "applewatch"
        case .mirror: "rectangle.on.rectangle"
        }
    }
}
