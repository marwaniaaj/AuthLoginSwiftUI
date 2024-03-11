//
//  AuthManager-DeleteAccount.swift
//  AuthLogin
//
//  Created by Marwa Abou Niaaj on 08/03/2024.
//

import AuthenticationServices
import FirebaseAuth
import GoogleSignIn

enum AuthErrors: Error {
    case ReauthenticateApple
    case ReauthenticateGoogle
    case RevokeAppleID
    case RevokeGoogle
}

extension AuthManager {

    /// Delete user account form Firebase Auth
    func deleteUserAccount() async throws {

        guard let user = Auth.auth().currentUser,
              let lastSignInDate = user.metadata.lastSignInDate else { return }

        let needsReAuth = !lastSignInDate.isWithinPast(minutes: 1)
        let providers = user.providerData.map { $0.providerID }

        do {
            if providers.contains("apple.com")  {
                let appleIDCredential = try await AppleSignInManager.shared.requestAppleAuthorization()

                if needsReAuth {
                    try await reauthenticateAppleID(appleIDCredential, for: user)
                }
                try await revokeAppleIDToken(appleIDCredential)
            }
            if providers.contains("google.com") {
                if needsReAuth {
                    try await reauthenticateGoogleAccount(for: user)
                }
                try await revokeGoogleAccount()
            }

            try await user.delete()
            updateState(user: user)
        }
        catch {
            print("FirebaseAuthError: Failed to delete auth user. \(error)")
            throw error
        }
    }

    /// Re-authenticate AppleID for given Firebase `User`, with given `AppleIDCredential`.
    /// - Parameters:
    ///   - appleIDCredential: `ASAuthorizationAppleIDCredential`.
    ///   - user: Firebase `User`.
    private func reauthenticateAppleID(
        _ appleIDCredential: ASAuthorizationAppleIDCredential,
        for user: User
    ) async throws {
        do {
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }

            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }

            let nonce = AppleSignInManager.nonce

            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nonce
            )

            try await user.reauthenticate(with: credential)
        }
        catch {
            throw AuthErrors.ReauthenticateApple
        }
    }
    
    /// Re-authenticate Google Account for given Firebase `User`.
    /// - Parameter user: Firebase `User`.
    private func reauthenticateGoogleAccount(for user: User) async throws {
        do {
            guard let googleUser = try await GoogleSignInManager.shared.signInWithGoogle() else {
                return
            }
            guard let idToken = googleUser.idToken?.tokenString else { return }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: googleUser.accessToken.tokenString
            )

            try await user.reauthenticate(with: credential)
        }
        catch {
            throw AuthErrors.ReauthenticateGoogle
        }
    }

    /// Revoke AppleID token using given `ASAuthorizationAppleIDCredential`'s authorization code.
    /// - Parameter appleIDCredential: `ASAuthorizationAppleIDCredential`.
    private func revokeAppleIDToken(_ appleIDCredential: ASAuthorizationAppleIDCredential) async throws {
        guard let authorizationCode = appleIDCredential.authorizationCode else { return }
        guard let authCodeString = String(data: authorizationCode, encoding: .utf8) else { return }

        do {
            try await Auth.auth().revokeToken(withAuthorizationCode: authCodeString)
        }
        catch {
            throw AuthErrors.RevokeAppleID
        }
    }
    
    /// Revoke Google Account (disconnect the connection between app and Google)
    private func revokeGoogleAccount() async throws {
        do {
            try await GIDSignIn.sharedInstance.disconnect()
        }
        catch {
            throw AuthErrors.RevokeGoogle
        }
    }
}

extension Date {
    func isWithinPast(minutes: Int) -> Bool {
        let now = Date.now
        let timeAgo = Date.now.addingTimeInterval(-1 * TimeInterval(60 * minutes))
        let range = timeAgo...now
        return range.contains(self)
    }
}
