//
//  PhotoSourceOption.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/05/2025.
//

import Foundation

enum PhotoSourceOption: ButtonActionOption {
    
    case photo
    case library

    var name: String {
        switch self {
        case .photo: return "Photo"
        case .library: return "Library"
        }
    }

    var icon: String {
        switch self {
        case .photo: return "camera.fill"
        case .library: return "photo.on.rectangle"
        }
    }

    var actionDescription: String {
        switch self {
        case .photo: return "Take a photo"
        case .library: return "Use a library"
        }
    }
    
}

//CustomWorkout
//SingleGoalWorkout
//PacerWorkout
