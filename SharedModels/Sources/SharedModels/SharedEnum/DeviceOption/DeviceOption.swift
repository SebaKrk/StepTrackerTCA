//
//  DeviceOption.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import Foundation

public enum DeviceOption: CaseIterable, Equatable {
    
    case watch
    case iphone
    case mirror
    
    public var title: String {
        switch self {
        case .watch:  "Watch"
        case .iphone: "iPhone"
        case .mirror: "Mirror"
        }
    }
    
    public var symbolName: String {
        switch self {
        case .watch:  "applewatch"
        case .iphone: "iphone"
        case .mirror: "rectangle.on.rectangle"
        }
    }
    
}
