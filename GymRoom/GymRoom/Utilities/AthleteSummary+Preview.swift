//
//  AthleteSummary+Preview.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 22/06/2026.
//

#if DEBUG
import Foundation
import SharedModels

// MARK: - Public preview factory

extension AthleteSummary {

    /// Generuje syntetyczny `AthleteSummary` z realistycznym profilem CrossFit-style
    /// klasy (warmup → WOD1 → WOD2 → cooldown). Deterministic (seed = `profileIndex`),
    /// więc preview re-runs produkują ten sam wykres — debugging zmian w UI bez szumu.
    ///
    /// `phaseScale` skaluje **wszystkie 4 fazy** proporcjonalnie. 1.0 = 30-min klasa,
    /// 2.0 = 60-min, 0.5 = 15-min. Sample rate (co 5 sek) zostaje stały — więcej
    /// sample'ów ogółem, ale per-minute bucketing daje proportionalnie więcej barów.
    static func preview(
        nick: String,
        profileIndex: Int,
        deviceID: UUID,
        classStart: Date,
        maxHR: Int = 190,
        phaseScale: Double = 1.0
    ) -> AthleteSummary {
        let profile = AthletePhaseProfile.preset(profileIndex)
        let samples = ClassSampleGenerator.samples(
            profile: profile,
            startTime: classStart,
            seed: UInt64(profileIndex + 1) &* 1_000_003,
            phaseScale: phaseScale
        )
        let leftAt = samples.last?.timestamp ?? classStart
        let duration = leftAt.timeIntervalSince(classStart)
        let analytics = ClassAnalytics.compute(
            samples: samples,
            maxHR: maxHR,
            duration: duration
        )
        return AthleteSummary(
            id: UUID(),
            deviceID: deviceID,
            nick: nick,
            maxHR: maxHR,
            joinedAt: classStart,
            leftAt: leftAt,
            samples: samples,
            analytics: analytics
        )
    }

    /// 4 atletów z odmiennymi profilami — pokazują różne style treningu:
    /// **aggressive starter** (Seba), **steady & strong** (Anna),
    /// **late peaker** (Marek), **cardio queen** (Kasia).
    static func previewClass(classStart: Date, phaseScale: Double = 1.0) -> [AthleteSummary] {
        [
            .preview(nick: "Seba",  profileIndex: 0, deviceID: previewDeviceID(1), classStart: classStart, phaseScale: phaseScale),
            .preview(nick: "Anna",  profileIndex: 1, deviceID: previewDeviceID(2), classStart: classStart, phaseScale: phaseScale),
            .preview(nick: "Marek", profileIndex: 2, deviceID: previewDeviceID(3), classStart: classStart, phaseScale: phaseScale),
            .preview(nick: "Kasia", profileIndex: 3, deviceID: previewDeviceID(4), classStart: classStart, phaseScale: phaseScale),
        ]
    }

    /// Hardcoded UUID per athlete — `AthleteColor.color(for:)` zwraca kolor
    /// deterministycznie z deviceID, więc Seba zawsze będzie tego samego koloru.
    private static func previewDeviceID(_ index: Int) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-00000000000\(index)") ?? UUID()
    }
}

// MARK: - Phase profile

private struct PhaseBand {
    let mean: Int
    let variance: Int
}

private struct AthletePhaseProfile {
    let warmup: PhaseBand
    let wod1: PhaseBand
    let wod2: PhaseBand
    let cooldown: PhaseBand

    static func preset(_ index: Int) -> AthletePhaseProfile {
        switch index % 4 {
        case 0:
            // Beast mode — wysoki HR wszędzie, duże swings. ~390 kcal / klasa.
            return AthletePhaseProfile(
                warmup:   PhaseBand(mean: 115, variance: 10),
                wod1:     PhaseBand(mean: 180, variance: 14),
                wod2:     PhaseBand(mean: 175, variance: 16),
                cooldown: PhaseBand(mean: 130, variance: 12)
            )
        case 1:
            // Standard intensity — średnie HR, umiarkowane swings. ~320 kcal / klasa.
            return AthletePhaseProfile(
                warmup:   PhaseBand(mean: 100, variance: 6),
                wod1:     PhaseBand(mean: 155, variance: 10),
                wod2:     PhaseBand(mean: 160, variance: 11),
                cooldown: PhaseBand(mean: 105, variance: 8)
            )
        case 2:
            // Beginner — niski HR, mała wariancja (jeszcze nie umie wycisnąć z siebie max). ~220 kcal.
            return AthletePhaseProfile(
                warmup:   PhaseBand(mean: 82,  variance: 5),
                wod1:     PhaseBand(mean: 120, variance: 7),
                wod2:     PhaseBand(mean: 125, variance: 8),
                cooldown: PhaseBand(mean: 88,  variance: 5)
            )
        default:
            // Cardio queen — stabilny średni HR, świetny szybki cooldown. ~280 kcal.
            return AthletePhaseProfile(
                warmup:   PhaseBand(mean: 95,  variance: 4),
                wod1:     PhaseBand(mean: 140, variance: 6),
                wod2:     PhaseBand(mean: 150, variance: 7),
                cooldown: PhaseBand(mean: 85,  variance: 4)
            )
        }
    }
}

// MARK: - Class phases (5 + 10 + 10 + 5 = 30 min)

private enum ClassPhase: CaseIterable {
    case warmup, wod1, wod2, cooldown

    var duration: TimeInterval {
        switch self {
        case .warmup:   return 5 * 60
        case .wod1:     return 10 * 60
        case .wod2:     return 10 * 60
        case .cooldown: return 5 * 60
        }
    }

    func band(in profile: AthletePhaseProfile) -> PhaseBand {
        switch self {
        case .warmup:   return profile.warmup
        case .wod1:     return profile.wod1
        case .wod2:     return profile.wod2
        case .cooldown: return profile.cooldown
        }
    }
}

// MARK: - Sample generator (random walk z return-to-mean)

private enum ClassSampleGenerator {

    /// Generuje sample'e @ co 5 sekund. Per phase: `phase.duration × phaseScale / 5`
    /// sample'ów. Phase scale 1.0 = 30 min klasa (360 sample/athlete), 2.0 = 60 min
    /// (720 sample/athlete). Random walk wokół `mean per faza` z lekkim "return to
    /// mean" (dryft nie ucieka poza pasmo).
    ///
    /// `activeEnergy` jest **cumulative** (jak w production, gdzie Watch loguje od
    /// Start Workout) — bez tego `ClassAnalytics.totalCalories = last - first = 0`.
    /// Inkrement per sample = `max(0, 0.12 × bpm − 6)` kcal/min — uproszczona Keytel
    /// formula (waga≈75, wiek≈30). Skaluje się proporcjonalnie z czasem klasy.
    static func samples(
        profile: AthletePhaseProfile,
        startTime: Date,
        seed: UInt64,
        phaseScale: Double = 1.0
    ) -> [HRSample] {
        var rng = SeededRNG(seed: seed)
        var samples: [HRSample] = []
        var currentTime = startTime
        let sampleInterval: TimeInterval = 5
        var cumulativeKcal: Double = 0

        for phase in ClassPhase.allCases {
            let band = phase.band(in: profile)
            let scaledDuration = phase.duration * phaseScale
            let count = Int(scaledDuration / sampleInterval)
            var current = band.mean

            for _ in 0..<count {
                let drift = Int.random(in: -band.variance...band.variance, using: &rng)
                let pullToMean = (band.mean - current) / 4
                current = max(50, min(200, current + drift / 2 + pullToMean))

                let kcalPerMinute = max(0, 0.12 * Double(current) - 6)
                cumulativeKcal += kcalPerMinute * (sampleInterval / 60.0)

                samples.append(HRSample(
                    timestamp: currentTime,
                    bpm: current,
                    activeEnergy: cumulativeKcal
                ))
                currentTime.addTimeInterval(sampleInterval)
            }
        }
        return samples
    }
}

// MARK: - Seeded RNG (LCG)

/// Linear congruential generator — deterministyczny stream UInt64 z seedu.
/// Stała mnożnika z Knuth's MMIX (`6364136223846793005` → 64-bit LCG).
private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}

#endif
