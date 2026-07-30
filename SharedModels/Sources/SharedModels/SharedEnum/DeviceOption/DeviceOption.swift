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
/// `HKLiveWorkoutDataSource` auto-pairs any BLE heart-rate sensor. `.hrBelt`,
/// `.iphone` and `.airPods` differ only in the guidance shown to the user (a
/// dedicated chest strap, AirPods, or any other broadcasting HR device).
///
/// Presentation (icons, localized titles) lives in `DeviceView` — this enum
/// stays a pure domain value shared across targets.
public enum DeviceOption: CaseIterable, Equatable {

    case watch
    case hrBelt
    case iphone
    /// AirPods (Pro 3 / iOS 26+) as an HR source. Under the hood identical to
    /// `.iphone` — an iPhone-standalone session with HR arriving through
    /// HealthKit (`HKLiveWorkoutDataSource`), NOT via the app's `0x180D` BLE
    /// scan. The separate case exists purely for presentation and to show the
    /// correct guidance.
    case airPods
    case mirror

}
