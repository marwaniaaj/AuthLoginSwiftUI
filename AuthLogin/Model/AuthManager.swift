//
//  AuthManager.swift
//  AuthLogin
//
//  Created by Marwa Abou Niaaj on 29/11/2023.
//

import AuthenticationServices
import FirebaseAuth
import FirebaseCore

/// An environment singleton responsible for handling
/// Firebase authentication in app.
class AuthManager: ObservableObject {

    /// Current Firebase auth user.
    @Published var user = Auth.auth().currentUser

    /// Boolean value indicates wether user is anonymous or not
    @Published var isAnonymous = Auth.auth().currentUser?.isAnonymous ?? false

    /// Boolean value indicates wether user is authenticated or not.
    @Published var isAuthenticatedUser = Auth.auth().currentUser != nil

    /// Auth state listener handler
    private var authStateHandle: AuthStateDidChangeListenerHandle!

    init() {
        // Start listening to auth changes upon initialization.
        configureAuthStateChanges()
    }

    // MARK: - Auth State
    /// Add listener for changes in the authorization state
    func configureAuthStateChanges() {
        authStateHandle = Auth.auth().addStateDidChangeListener { auth, user in
            self.isAuthenticatedUser = user != nil
            self.isAnonymous = user?.isAnonymous ?? false
            print("Auth changed: \(self.isAuthenticatedUser)")
        }
    }

    /// Remove listener for changes in the authorization state
    func removeAuthStateListener() {
        Auth.auth().removeStateDidChangeListener(authStateHandle)
    }

    // MARK: - Sign-in
    @discardableResult
    func signInAnonymously() async throws -> AuthDataResult? {
        do {
            let result = try await Auth.auth().signInAnonymously()
            print("FirebaseAuthSuccess: Sign in anonymously, UID:(\(String(describing: result.user.uid)))")
            return result
        }
        catch {
            print("FirebaseAuthError: failed to sign in anonymously: \(error.localizedDescription)")
            throw error
        }
    }
}

