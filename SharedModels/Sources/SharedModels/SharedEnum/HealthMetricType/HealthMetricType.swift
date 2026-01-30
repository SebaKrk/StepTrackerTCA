//
//  HealthMetricType.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 18/10/2025.
//

import Foundation

public enum HealthMetricType: String, CaseIterable, Identifiable, Sendable {
    
    case rhr
    case hrv
    case sleep
    case activity
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .rhr: return "heart.fill"
        case .hrv: return "waveform.path.ecg"
        case .sleep: return "bed.double.fill"
        case .activity: return "flame.fill"
        }
    }
    
    public var title: String {
        switch self {
        case .rhr:
            return String(localized: "RHR", bundle: .module)
        case .hrv:
            return String(localized: "HRV", bundle: .module)
        case .sleep:
            return String(localized: "Sleep", bundle: .module)
        case .activity:
            return String(localized: "Activity", bundle: .module)
        }
    }
    
    public var fullName: String {
        switch self {
        case .rhr:
            return String(localized: "Resting Heart Rate", bundle: .module)
        case .hrv:
            return String(localized: "Heart Rate Variability", bundle: .module)
        case .sleep:
            return String(localized: "Sleep Quality", bundle: .module)
        case .activity:
            return String(localized: "Activity Level", bundle: .module)
        }
    }
    
    public var description: String {
        switch self {
        case .rhr:
            return "Tętno spoczynkowe (RHR) to liczba uderzeń serca na minutę podczas odpoczynku. Niższe wartości zazwyczaj wskazują na lepszą kondycję cardiovascular i regenerację. Apple Watch mierzy RHR automatycznie podczas snu i odpoczynku."
            
        case .hrv:
            return "Zmienność rytmu serca (HRV) mierzy wariacje czasowe między kolejnymi uderzeniami serca. Wyższa HRV sugeruje lepszą równowagę układu nerwowego i gotowość do treningów. Jest to jeden z najlepszych wskaźników regeneracji."
            
        case .sleep:
            return "Jakość snu oceniana jest na podstawie czasu spędzonego w różnych fazach snu (głęboki, REM, lekki). Lepszy sen przyczynia się do lepszej regeneracji i gotowości treningowej. Zalecane 7-9 godzin dla dorosłych."
            
        case .activity:
            return "Poziom aktywności mierzy energię wydatkowaną podczas poprzedniego dnia. Zbyt wysoka aktywność może wpływać negatywnie na dzisiejszą gotowość. Monitoring obciążenia treningowego pomaga uniknąć przetrenowania."
        }
    }
    
    public var unit: String {
        switch self {
        case .rhr: return "bpm"
        case .hrv: return "ms"
        case .sleep: return "hours"
        case .activity: return "kcal"
        }
    }
    
    public var missingDataMessage: String {
        switch self {
        case .rhr:
            return String(localized: "No heart rate data available. Check Health app.", defaultValue: "No heart rate data available. Check Health app.")
        case .hrv:
            return String(localized: "No HRV data found. Regular measurements required.", defaultValue: "No HRV data found. Regular measurements required.")
        case .sleep:
            return String(localized: "No sleep data. Track your sleep to see insights.", defaultValue: "No sleep data. Track your sleep to see insights.")
        case .activity:
            return String(localized: "No calories burned data available.", defaultValue: "No calories burned data available.")
        }
    }
    
}
