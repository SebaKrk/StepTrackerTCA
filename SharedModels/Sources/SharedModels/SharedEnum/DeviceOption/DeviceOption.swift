//
//  DeviceOption.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import Foundation

/// HR-source choice in the pre-workout device picker.
///
/// Only two session modes exist underneath: `.watch` starts a Watch-primary
/// mirrored session; every other option runs iPhone-standalone, where
/// `HKLiveWorkoutDataSource` auto-pairs any BLE heart-rate sensor. `.hrBelt`
/// and `.iphone` differ only in the guidance shown to the user (a dedicated
/// chest strap vs any other broadcasting HR device).
///
/// Presentation (icons, localized titles) lives in `DeviceView` — this enum
/// stays a pure domain value shared across targets.
public enum DeviceOption: CaseIterable, Equatable {

    case watch
    case hrBelt
    case iphone
    case mirror

}
