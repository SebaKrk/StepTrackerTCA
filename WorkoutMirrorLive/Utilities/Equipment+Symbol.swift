//
//  Equipment+Symbol.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/11/2026.
//

import SharedModels

extension Equipment {

    /// Symbol drawn by `EquipmentSymbolImage` beside the equipment's name.
    ///
    /// SF Symbols has no kettlebell, sandbag or wall ball, so those are the app's own drawings.
    var symbolName: String {
        switch self {
        case .barbell, .dumbbell: "dumbbell"
        case .kettlebell: "\(EquipmentSymbolImage.customPrefix)kettlebell"
        case .medicineBall: "\(EquipmentSymbolImage.customPrefix)wallball"
        case .sandbag: "\(EquipmentSymbolImage.customPrefix)sandbag"
        }
    }
}
