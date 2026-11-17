//
//  ScanLanguage.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 17/11/2026.
//

import Foundation

/// The language the proxy should write free-text fields in.
public enum ScanLanguage {

    /// The device language as an English name ("Polish").
    ///
    /// Sent with every request rather than stored on the server: the cached system
    /// prompt stays byte-identical, so a language change never costs a cache miss.
    public static func preferredName() -> String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return Locale(identifier: "en").localizedString(forLanguageCode: code) ?? "English"
    }
}
