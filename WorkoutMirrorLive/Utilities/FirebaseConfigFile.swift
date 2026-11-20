//
//  FirebaseConfigFile.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import FirebaseCore
import Foundation

/// Maps an app bundle to the Firebase config file of its own project.
enum FirebaseConfigFile {

    /// Firebase options for the bundle's project, or `nil` when no config ships with it.
    static func options(for bundle: Bundle) -> FirebaseOptions? {
        guard
            let name = resourceName(for: bundle.bundleIdentifier),
            let path = bundle.path(forResource: name, ofType: "plist")
        else { return nil }
        return FirebaseOptions(contentsOfFile: path)
    }

    private static func resourceName(for bundleID: String?) -> String? {
        switch bundleID {
        case "ss.WorkoutMirrorLive": "GoogleService-Info-Dev"
        case "ss.lf.WorkoutMirrorLive": "GoogleService-Info"
        default: nil
        }
    }
}
