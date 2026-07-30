//
//  GymRoomFileLogger.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 25/06/2026.
//

import Foundation

/// File-based logger dla iPad GymRoom — analog `WorkoutFileLogger` z SharedModels
/// (używany w WorkoutMirrorLive iPhone). Zapisuje timestamped events do plików
/// `ipad_gymroom_log_<timestamp>.txt` w `Documents/`. Pliki dostępne w **Files.app**
/// na iPadzie (gdy `UIFileSharingEnabled = YES` w Info.plist), do exportu na Mac.
///
/// **Use case**: diagnostyka peer connect/disconnect, session lifecycle, BLE state.
/// Plikowy log uzupełnia `Logger.gymRoom` (unified Logger) — gdy nie ma USB +
/// Console.app, można sczytać plik na iPadzie i wysłać.
///
/// **Prefix convention** (jak w WorkoutFileLogger):
/// - `[Class]` — session lifecycle (start, end, ERROR)
/// - `[Session]` — DB persistence events
/// - `[Peer]` — peer connect/suspend/reconnect/disconnect
///
/// **Debug-only** — wszystkie metody są no-op w release builds.
public actor GymRoomFileLogger {

    public static let shared = GymRoomFileLogger()

    // MARK: - Private

    private var startDate: Date = Date()

    /// Plik = `ipad_gymroom_log_<unix_timestamp>.txt`. Nowy timestamp przy każdym
    /// `reset()`, czyli **nowy plik per klasa** — dzięki temu pliki nie rosną
    /// niekontrolowanie (każda klasa to osobny readable plik).
    private var fileURL: URL {
        let timestamp = Int(startDate.timeIntervalSince1970)
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ipad_gymroom_log_\(timestamp).txt")
    }

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    // MARK: - Public API

    /// Reset — nowy plik z headerem. Wołać na class start (`.startTapped` reducer
    /// action). Debug-only.
    public func reset() {
        #if DEBUG
        startDate = Date()
        let header = "=== GymRoom Class Log \(startDate) ===\n"
        try? header.write(to: fileURL, atomically: true, encoding: .utf8)
        #endif
    }

    /// Append timestamped line do bieżącego pliku log'u. Debug-only.
    public func log(_ message: String) {
        #if DEBUG
        let time = timeFormatter.string(from: Date())
        let line = "[\(time)] \(message)\n"
        append(line)
        #endif
    }

    /// URL bieżącego pliku log'u — przydatne dla share sheet / export UI.
    public func currentFileURL() -> URL { fileURL }

    // MARK: - Private

    private func append(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: fileURL)
        }
    }
}
