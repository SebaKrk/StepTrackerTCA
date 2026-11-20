//
//  TeamServiceError+Offline.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/10/2026.
//

import FirebaseFirestore
import Foundation

extension TeamServiceError {

    /// `true` when the call failed only for want of a connection, so the same call can succeed on a retry.
    static func isOffline(_ error: any Error) -> Bool {
        let error = error as NSError
        if error.domain == FirestoreErrorDomain {
            return error.code == FirestoreErrorCode.Code.unavailable.rawValue
        }
        return error.domain == NSURLErrorDomain
    }
}
