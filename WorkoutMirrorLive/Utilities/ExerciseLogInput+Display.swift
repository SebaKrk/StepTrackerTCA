//
//  ExerciseLogInput+Display.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import Foundation
import SharedModels

extension ExerciseLogInput {

    /// Equipment named under the movement, or nothing when the movement never varies.
    ///
    /// Lives in the app, not SharedModels: the package can localize, but keeping every
    /// user-facing word in one catalog beats splitting them across two.
    var equipmentCaption: String? {
        guard exerciseType?.supportsEquipmentSelection == true else { return nil }
        if equipmentSelection == .some(.none) {
            return String(localized: "No equipment", bundle: .main)
        }
        return effectiveEquipment?.displayName
    }

    /// Symbol beside that caption: a body when the athlete chose no equipment.
    var equipmentSymbol: String {
        equipmentSelection == .some(.none) ? "figure" : "dumbbell"
    }
}
