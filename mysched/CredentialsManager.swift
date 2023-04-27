//
//  CredentialsManager.swift
//  mysched
//
//  Created by Ryan Sheridan on 27/04/2023.
//

import Foundation
import KeychainSwift

class CredentialsManager {
    static let shared = CredentialsManager()
    private let keychain = KeychainSwift()

    private let userIDKey = "userID"
    private let passwordKey = "password"

    private init() {}
    
    public struct Credentials: Codable {
        let userID: String
        let password: String
    }

    func saveCredentials(userID: String, password: String) -> Bool {
        let userIDSuccess = keychain.set(userID, forKey: userIDKey)
        let passwordSuccess = keychain.set(password, forKey: passwordKey)
        return userIDSuccess && passwordSuccess
    }

    func deleteCredentials() -> Bool {
        let userIDSuccess = keychain.delete(userIDKey)
        let passwordSuccess = keychain.delete(passwordKey)
        return userIDSuccess && passwordSuccess
    }

    func loadCredentials() -> Credentials? {
        let keychain = KeychainSwift()

        if let userID = keychain.get("userID"), let password = keychain.get("password") {
            let credentials = Credentials(userID: userID, password: password)
            return credentials
        } else {
            print("Error retrieving credentials from Keychain")
            return nil
        }
    }
    
    func hasSavedCredentials() -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: userIDKey,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnAttributes: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        return status != errSecItemNotFound
    }

}
