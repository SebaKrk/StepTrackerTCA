//
//  AppGroup.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation

/// The App Group the app and its widget share, chosen by the running bundle.
public enum AppGroup {

    /// Identifier of the shared container for this build's bundle family.
    public static let identifier: String = {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        return bundleID.hasPrefix("ss.lf.")
            ? "group.com.ss.lf.WorkoutMirrorLive"
            : "group.com.ss.WorkoutMirrorLive"
    }()
}
