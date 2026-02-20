//
//  APIKeyClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import ComposableArchitecture
import Foundation
import Security

/// Manages the Anthropic API key stored securely in Keychain.
struct APIKeyClient: Sendable {
    var load:   @Sendable () -> String?
    var save:   @Sendable (String) -> Void
    var delete: @Sendable () -> Void
}

extension DependencyValues {
    nonisolated var apiKeyClient: APIKeyClient {
        get { self[APIKeyClient.self] }
        set { self[APIKeyClient.self] = newValue }
    }
}

extension APIKeyClient: DependencyKey {

    nonisolated private static let account = "anthropic_api_key"
    nonisolated private static let service = "ss.WorkoutMirrorLive"

    static let liveValue = APIKeyClient(
        load: {
            let query: [CFString: Any] = [
                kSecClass:       kSecClassGenericPassword,
                kSecAttrAccount: account,
                kSecAttrService: service,
                kSecReturnData:  true,
                kSecMatchLimit:  kSecMatchLimitOne
            ]
            var result: AnyObject?
            guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
                  let data = result as? Data,
                  let key = String(data: data, encoding: .utf8),
                  !key.isEmpty else { return nil }
            return key
        },
        save: { key in
            let data = Data(key.utf8)
            let deleteQuery: [CFString: Any] = [
                kSecClass:       kSecClassGenericPassword,
                kSecAttrAccount: account,
                kSecAttrService: service
            ]
            SecItemDelete(deleteQuery as CFDictionary)

            let addQuery: [CFString: Any] = [
                kSecClass:                kSecClassGenericPassword,
                kSecAttrAccount:          account,
                kSecAttrService:          service,
                kSecValueData:            data,
                kSecAttrAccessible:       kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            SecItemAdd(addQuery as CFDictionary, nil)
        },
        delete: {
            let query: [CFString: Any] = [
                kSecClass:       kSecClassGenericPassword,
                kSecAttrAccount: account,
                kSecAttrService: service
            ]
            SecItemDelete(query as CFDictionary)
        }
    )

    static var testValue = APIKeyClient(
        load:   { nil },
        save:   { _ in },
        delete: {}
    )
}
