//
//  KeychainService.swift
//  ntfy
//
//  Created by Achmad Mahardi on 19/12/25.
//

import Foundation
import KeychainAccess

@MainActor
final class KeychainService {
    static let shared = KeychainService()

    private let keychain: Keychain

    private init() {
        keychain = Keychain(service: BuildConfiguration.current.keychainService)
            .accessibility(.afterFirstUnlock)
    }

    // MARK: - Password Management

    func setPassword(_ password: String, for topicId: UUID) throws {
        try keychain.set(password, key: passwordKey(for: topicId))
    }

    func getPassword(for topicId: UUID) -> String? {
        try? keychain.get(passwordKey(for: topicId))
    }

    func removePassword(for topicId: UUID) throws {
        try keychain.remove(passwordKey(for: topicId))
    }

    // MARK: - Credential Management

    func hasCredentials(for topicId: UUID) -> Bool {
        getPassword(for: topicId) != nil
    }

    func basicAuthHeader(username: String, topicId: UUID) -> String? {
        guard let password = getPassword(for: topicId) else { return nil }
        let credentials = "\(username):\(password)"
        guard let data = credentials.data(using: .utf8) else { return nil }
        return "Basic \(data.base64EncodedString())"
    }

    // MARK: - Private

    private func passwordKey(for topicId: UUID) -> String {
        "topic.\(topicId.uuidString).password"
    }
}
