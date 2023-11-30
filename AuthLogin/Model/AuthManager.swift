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

    /// Boolean value indicates whether user is authenticated or not.
    @Published var isAuthenticatedUser = Auth.auth().currentUser != nil

    /// Boolean value indicates whether user is authenticated anonymously or not
    @Published var isAnonymous = Auth.auth().currentUser?.isAnonymous ?? false

    /// Auth state listener handler
    private var authStateHandle: AuthStateDidChangeListenerHandle!

    init() {
        // Start listening to auth changes.
        configureAuthStateChanges()
    }

    // MARK: - Auth State
    /// Add listener for changes in the authorization state.
    func configureAuthStateChanges() {
        authStateHandle = Auth.auth().addStateDidChangeListener { auth, user in
            self.user = user
            self.isAuthenticatedUser = user != nil
            self.isAnonymous = user?.isAnonymous ?? false
            print("Auth changed: \(self.isAuthenticatedUser)")
        }

    }

    /// Remove listener for changes in the authorization state.
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

    // MARK: - Sign Out
    /// Sign out a user from Firebase Provider.
    func firebaseProviderSignOut(_ user: User) {
        let providers = user.providerData.map { $0.providerID }.joined(separator: ", ")

        if providers.contains("apple.com")  {
            // TODO: Sign out from Apple
        }
        if providers.contains("google.com") {
            // TODO: Sign out from Google
        }
    }

    /// Sign out current `Firebase` auth user
    func signOut() async throws {
        if let user = Auth.auth().currentUser {

            // Sign out current authenticated user in Firebase
            do {
                firebaseProviderSignOut(user)
                try Auth.auth().signOut()
            }
            catch let error as NSError {
                print("FirebaseAuthError: failed to sign out from Firebase, \(error)")
                throw error
            }
        }
    }
}

