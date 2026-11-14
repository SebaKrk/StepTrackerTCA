//
//  DiagnosticsBundleError.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import Foundation

enum DiagnosticsBundleError: Error {

    /// File coordination reported success but handed back no archive.
    case archiveMissing
}
