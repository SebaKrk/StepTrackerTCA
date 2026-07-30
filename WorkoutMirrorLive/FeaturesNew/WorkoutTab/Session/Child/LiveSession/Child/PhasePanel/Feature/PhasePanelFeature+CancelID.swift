//
//  PhasePanelFeature+CancelID.swift
//  WorkoutMirrorLive
//

/// Cancel identifiers used by `PhasePanelFeature` effects.
nonisolated enum PhasePanelFeatureCancelID: Hashable, Sendable {

    /// Identifies the per-phase timer effect started on `.view(.appeared)`
    /// and rescheduled on each `.timerTick`.
    case timer

}
