//
//  GoogleSignInManager.swift
//  AuthLogin
//
//  Created by Marwa Abou Niaaj on 01/12/2023.
//

import GoogleSignIn

class GoogleSignInManager {

    /// GoogleSignInManager shared instance.
    static let shared = GoogleSignInManager()

    /// Google auth result
    typealias GoogleAuthResult = (GIDGoogleUser?, Error?) -> Void

    private init() {}

    @MainActor
    /// Sign in with `Google`.
    /// - Returns: Optional `GIDGoogleUser`.
    func signInWithGoogle() async throws -> GIDGoogleUser? {
        // Check previous sign-in.
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            do {
                try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                return try await GIDSignIn.sharedInstance.currentUser?.refreshTokensIfNeeded()
            }
            catch {
                // Previous sign in available, but was previously revoked, so initiate sign in flow.
                return try await googleSignInFlow()
            }
        } else {
            return try await googleSignInFlow()
        }
    }

    @MainActor
    private func googleSignInFlow() async throws -> GIDGoogleUser? {
        // Accessing rootViewController through shared instance of UIApplication.
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        guard let rootViewController = windowScene.windows.first?.rootViewController else { return nil }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        return result.user
    }

    /// Sign out from `Google`.
    func signOutFromGoogle() {
        GIDSignIn.sharedInstance.signOut()
    }
}
