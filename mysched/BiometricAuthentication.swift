//
//  BiometricAuthentication.swift
//  mysched
//
//  Created by Ryan Sheridan on 27/04/2023.
//

import Foundation
import LocalAuthentication

class BiometricAuthentication {
    static let shared = BiometricAuthentication()
    
    private init() {}

    public func showPasscodeAuthentication(completion: @escaping (Bool) -> Void, failure: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Authenticate to access your saved login details."
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        completion(true)
                    } else {
                        if let error = authenticationError as? LAError, error.code == .userCancel {
                            print("User canceled authentication")
                            completion(false)
                        } else {
                            print("Authentication failed: \(String(describing: authenticationError))")
                            failure(false)
                        }
                    }
                }
            }
        } else {
            print("Passcode authentication not available")
            failure(false)
        }
    }

    
    public func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access your saved login details."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        completion(true)
                    } else {
                        print("Authentication failed: \(String(describing: authenticationError))")
                        completion(false)
                    }
                }
            }
        } else {
            print("Biometric authentication not available")
            self.showPasscodeAuthentication(completion: completion, failure: { _ in completion(false) })
        }
    }

}
