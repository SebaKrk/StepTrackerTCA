//
//  Bundle+SharedModels.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 06/04/2026.
//

import Foundation

public extension Bundle {

    /// The bundle for the SharedModels Swift Package.
    ///
    /// Use this when calling `String(localized:bundle:)` from outside the package
    /// (e.g. Watch App targets) so that `Localizable.xcstrings` inside SharedModels
    /// is consulted instead of the caller's own bundle.
    static var sharedModels: Bundle { .module }

}
