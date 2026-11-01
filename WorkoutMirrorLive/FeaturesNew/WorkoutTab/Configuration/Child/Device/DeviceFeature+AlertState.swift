//
//  DeviceFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension AlertState where Action == DeviceFeature.BroadcastAlertAction {

    /// "Other HR device" (Garmin/Polar/Suunto…) is invisible to the iPhone until
    /// the user enables HR broadcasting on it.
    static let broadcastReminder = Self {
        TextState(String(localized: "Enable heart rate broadcasting"))
    } actions: {
        ButtonState(action: .confirmTapped(.iphone)) {
            TextState(String(localized: "OK"))
        }
        ButtonState(role: .cancel) {
            TextState(String(localized: "Cancel"))
        }
    } message: {
        TextState(String(localized: "Turn on heart rate broadcasting on your device — on sport watches look for a setting like \"Broadcast Heart Rate\" (Garmin) or \"Share heart rate\" (Polar). Without it the iPhone will not receive any readings."))
    }

    /// Heart rate on AirPods is a Pro 3 (2025) feature — only surfaces during a
    /// workout, and only with both buds in the ears and paired to this iPhone.
    static let airPodsReminder = Self {
        TextState(String(localized: "AirPods Pro 3 required"))
    } actions: {
        ButtonState(action: .confirmTapped(.airPods)) {
            TextState(String(localized: "OK"))
        }
        ButtonState(role: .cancel) {
            TextState(String(localized: "Cancel"))
        }
    } message: {
        TextState(String(localized: "Heart rate is measured only by AirPods Pro 3. Put both AirPods in your ears and keep them connected to this iPhone — readings appear once the workout starts."))
    }
}
