//
//  AppScreen.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 29/07/2025.
//

import SwiftUI

/// Enum representing the available screens (tabs) in the application.
///
/// Each case corresponds to a specific tab, with its own unique functionality and purpose.
/// to enable seamless usage in SwiftUI and navigation systems.
enum AppScreen: Codable, Hashable, Identifiable, CaseIterable {

    case live

    case workout

    case person

    case activities

    case stats

    case sharing

    var id: Self { self }

}

extension AppScreen {
    
    @ViewBuilder
    var label: some View {
        switch self {
        case .live:
            Label(
                String(localized: "Live",
                       comment: "The Live Tab displays real-time heart rate and workout data."),
                systemImage: "figure"//"waveform.path.ecg"
            )

        case .workout:
            Label(
                String(localized: "Workout",
                       comment: "The Workout Tab lets users review or start workouts."),
                systemImage: "figure.run"
            )
            
        case .person:
            Label(
                String(localized: "Profile",
                       comment: "The Profile Tab contains user info, connected sensors, and settings."),
                systemImage: "person.fill"
            )
        case .activities:
            Label(
                String(localized: "Activities",
                       comment: "The Activities Tab shows a list of completed workouts with details and quick actions."),
                systemImage: "calendar"
            )
        case .stats:
            Label(
                String(localized: "Stats",
                       comment: "The Stats Tab presents charts and analytics for workouts and health metrics."),
                systemImage: "house"
            )
        case .sharing:
            Label(
                String(localized: "Sharing",
                       comment: "The Sharing Tab shows the team you joined and shared workout activity."),
                systemImage: "person.3.fill"
            )
        }
    }
    
    var title: String {
        switch self {
        case .live:
            return String(localized: "Live", comment: "The Live Tab displays real-time heart rate and workout data.")
        case .workout:
            return String(localized: "Workout", comment: "The Workout Tab lets users review or start workouts.")
        case .person:
            return String(localized: "Profile", comment: "The Profile Tab contains user info, connected sensors, and settings.")
        case .activities:
            return String(localized: "Activities", comment: "The Activities Tab shows a list of completed workouts with details and quick actions.")
        case .stats:
            return String(localized: "Stats", comment: "The Stats Tab presents charts and analytics for workouts and health metrics.")
        case .sharing:
            return String(localized: "Sharing", comment: "The Sharing Tab shows the team you joined and shared workout activity.")
        }
    }
    
    var image: String {
        switch self {
        case .live: return "figure"//"waveform.path.ecg"
        case .workout: return "figure.run"
        case .person: return "person.fill"
        case .activities: return "calendar"
        case .stats: return "house"
        case .sharing: return "person.3.fill"
        }
    }
}


//zakladaka live:
//• glowna funkcja aplikacji tzn pokazanie aktualnego tetna, strefy tetna oraz spalonych kalori.
//  uzytkownik bedzie wiedzial na jakim procencie wytrzymalosci sie znajduje
//•  Czas trwania sesji.

// start treningu -> mirrorwanie treningu -> zakonczenie = podumowaniem
//  Analiza po treningu (raporty)
//    -   Średnie tętno, maksymalne, wykresy.
//    -    Czas spędzony w każdej strefie.
//    -    Spalona energia.
//    -    Eksport do PDF / CSV.

//zakladaka workout:
//• dwie zakladki do wyboru u gory
//• planowanie treningu
//    - Rodzaje treningów do wyboru
//    - Bieganie, rower, interwały, siłowy, HIIT, itd.
//    - Każdy typ może mieć inne metryki i cele.
//    - Użytkownik może ustawić własny cel (czas, kcal, strefa tętna, dystans).
//• lista treningow ktore odbyly sie za pomoca mojej aplikacji (moze byc tez lista wszystkich treninogw z helt kit + szybka opcja tylko za pomoca mojej app)
//•


//zakladaka perosn:
//•    ustawienia sensorów / BLE
//•    dane użytkownika (wiek, płeć, waga…)
//•    prywatność / HealthKit
//•    eksport danych
//•    dane kontaktowe / feedback
//Profil Użytkownika:
//Dane podstawowe: wiek, waga, wzrost, płeć (kluczowe do dokładnego obliczania stref tętna i spalonych kalorii).
//Ustalenie tętna maksymalnego (HRmax) i spoczynkowego – automatycznie z formuły lub poprzez test wysiłkowy.
//Synchronizacja z Urządzeniami Zewnętrznymi:
//Natywna integracja z zegarkami (Apple Watch, Wear OS) i czujnikami tętna na klatkę piersiową (np. Polar, Garmin) przez Bluetooth. To jest główne źródło danych.

//🔹 1. Wejście do zakładki Live
//     ✅ Sprawdzamy stan sesji:
//    → brak aktywnego treningu? ➝ ekran startowy
//    → jest aktywna sesja? ➝ uruchamiam  ekran aktywnego treningu(4)
//🔹 2. Brak aktywnego treningu → ekran przygotowania
//    •    Ekran: LiveStartView
//    •    Pokazuje:
//    •    Krótka instrukcja (“Połącz się z czujnikiem, wybierz typ treningu”)
//    •    Stan połączenia z czujnikiem tętna (Bluetooth / HealthKit)
//    •    Przycisk Rozpocznij trening (nieaktywny jeśli brak czujnika)
//    •    Wybór typu treningu (ikony / list picker)
//    •    Ewentualne alerty (np. “Brak uprawnień do HealthKit”)
//🔹 3. Po sparowaniu czujnika i wybraniu treningu
//    •    Przycisk Rozpocznij staje się aktywny
//    •    Kliknięcie ➝ przejście do LiveWorkoutView
//🔹 4. Widok aktywnego treningu (LiveWorkoutView)
//    •    Pokazuje w czasie rzeczywistym:
//    •    ❤️ BPM + strefa tętna
//    •    🔥 Kalorie
//    •    ⏱ Czas trwania
//    •    % HRmax
//    •    🛑 Pauza / Zakończ
//    •    Może zawierać:
//    •    Live Activity
//    •    Haptic Feedback przy zmianie strefy
//🔹 5. Pauza → pokazuje menu
//•    Wznowienie / zakończenie
//•    Podgląd wyników cząstkowych
//
//🔹 6. Zakończenie treningu
//•    Przejście do WorkoutSummaryView:
//•    Tętno śr./max
//•    Czas
//•    Spalone kcal
//•    Czas w każdej strefie
