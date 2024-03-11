//
//  AppleSignInManager.swift
//  AuthLogin
//
//  Created by Marwa Abou Niaaj on 01/12/2023.
//

import AuthenticationServices
import CryptoKit

/// An environment singleton responsible for
/// logging and authorization of Apple's sign-in flow in our app.
class AppleSignInManager: NSObject {

    /// AppleSignInManager shared instance.
    static let shared = AppleSignInManager()

    /// Un-hashed nonce.
    fileprivate static var currentNonce: String?

    /// Current un-hashed nonce
    static var nonce: String? {
        currentNonce ?? nil
    }

    private var continuation : CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    func requestAppleAuthorization() async throws -> ASAuthorizationAppleIDCredential {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let appleIdProvider = ASAuthorizationAppleIDProvider()
            let request = appleIdProvider.createRequest()
            requestAppleAuthorization(request)

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.performRequests()
        }
    }

    func requestAppleAuthorization(_ request: ASAuthorizationAppleIDRequest) {
        AppleSignInManager.currentNonce = randomNonceString()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(AppleSignInManager.currentNonce!)
    }
}

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if case let appleIDCredential as ASAuthorizationAppleIDCredential = authorization.credential {
            continuation?.resume(returning: appleIDCredential)
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
    }
}

// MARK: - Nonce
extension AppleSignInManager {

    /// Generate a random string -a cryptographically secure "nonce"- which will be used to make sure the ID token was granted specifically in response to the app's authentication request.
    /// - parameter length: integer
    /// - returns: string containing a cryptographically secure "nonce"
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }

        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    /// Secure Hashing Algorithm 2 (SHA-2) hashing with a 256-bit digest
    /// - parameter input: String containing nonce.
    /// - returns: String containing hash value of nonce.
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}
