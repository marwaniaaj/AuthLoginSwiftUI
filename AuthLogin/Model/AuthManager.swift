//
//  AuthManager.swift
//  AuthLogin
//
//  Created by Marwa Abou Niaaj on 29/11/2023.
//

import AuthenticationServices
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

enum AuthState {
    // Anonymously authenticated in Firebase.
    case authenticated
    // Authenticated in Firebase using one of service providers, and not anonymous.
    case signedIn
    // Not authenticated in Firebase.
    case signedOut
}

/// An environment singleton responsible for handling
/// Firebase authentication in app.
@MainActor
class AuthManager: ObservableObject {

    /// Current Firebase auth user.
    @Published var user: User?

    /// Auth state for current user.
    @Published var authState = AuthState.signedOut

    /// Auth state listener handler
    private var authStateHandle: AuthStateDidChangeListenerHandle!

    /// Common auth link errors.
    private let authLinkErrors: [AuthErrorCode.Code] = [
            .emailAlreadyInUse,
            .credentialAlreadyInUse,
            .providerAlreadyLinked
    ]

    init() {
        // Start listening to auth changes.
        configureAuthStateChanges()

        // Verify AppleID and Google credentials
        Task {
            await verifySignInProvider()
        }
    }

    // MARK: - Auth State
    /// Add listener for changes in the authorization state.
    func configureAuthStateChanges() {
        authStateHandle = Auth.auth().addStateDidChangeListener { auth, user in
            print("Auth changed: \(user != nil)")
            self.updateState(user: user)

            if let user {
                /*
                do {
                    try await firestore.getUserDocument(user)
                }
                catch FirestoreErrors.DocumentDoesNotExist {
                    print("User Document Does Not Exist!")
                    await verifyAuthTokenResult()
                    return
                }
                catch {
                    // Other errors
                }
                 */
            }
        }
    }

    /// Remove listener for changes in the authorization state.
    func removeAuthStateListener() {
        Auth.auth().removeStateDidChangeListener(authStateHandle)
    }

    /// Update auth state for given user.
    /// - Parameter user: `Optional` firebase user.
    internal func updateState(user: User?) {
        self.user = user
        let isAuthenticatedUser = user != nil
        let isAnonymous = user?.isAnonymous ?? false

        if isAuthenticatedUser {
            self.authState = isAnonymous ? .authenticated : .signedIn
        } else {
            self.authState = .signedOut
        }
    }

    // MARK: - Verify authentication

    /// Verify sign in providers, whether or not they have been revoked.
    private func verifySignInProvider() async {
        guard let providerData = Auth.auth().currentUser?.providerData else { return }
        var isAppleCredentialRevoked = false
        var isGoogleCredentialRevoked = false

        if providerData.contains(where: { $0.providerID == "apple.com" }) {
            isAppleCredentialRevoked = await !verifySignInWithAppleID()
        }

        if providerData.contains(where: { $0.providerID == "google.com" }) {
            isGoogleCredentialRevoked = await !verifyGoogleSignIn()
        }

        if isAppleCredentialRevoked && isGoogleCredentialRevoked {
            /// Sign out iff user not signed out, or signed in anonymously.
            if authState != .signedIn {
                do {
                    try await self.signOut()
                }
                catch {
                    print("FirebaseAuthError: verifySignInProvider() failed. \(error)")
                }
            }
        }
    }

    /// Verify AppleID provider.
    /// - Returns: Boolean indicates whether user is authorized, or authorization has been revoked
    private func verifySignInWithAppleID() async -> Bool {
        let appleIDProvider = ASAuthorizationAppleIDProvider()

        guard let providerData = Auth.auth().currentUser?.providerData,
              let appleProviderData = providerData.first(where: { $0.providerID == "apple.com" }) else {
            return false
        }

        do {
            let credentialState = try await appleIDProvider.credentialState(forUserID: appleProviderData.uid)
            return credentialState != .revoked && credentialState != .notFound
        }
        catch {
            return false
        }
    }

    /// Verify Google provider.
    /// - Returns: Boolean indicates whether user is authorized, or authorization has been revoked
    private func verifyGoogleSignIn() async -> Bool {
        guard let providerData = Auth.auth().currentUser?.providerData,
              providerData.contains(where: { $0.providerID == "google.com" }) else { return false }

        do {
            try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            return true
        }
        catch {
            return false // The Google sign in credential is either revoked or was not found.
        }
    }

    /// Validate and force refresh Auth token
    /// - Returns: Boolean indicates if token is valid or not.
    private func verifyAuthTokenResult() async -> Bool {
        do {
            try await Auth.auth().currentUser?.getIDTokenResult(forcingRefresh: true)
            return true
        }
        catch {
            print("Error retrieving id token result. \(error)")
            return false
        }
    }

    //MARK: - Authenticate
    private func authenticateUser(credentials: AuthCredential) async throws -> AuthDataResult? {
        // If we have authenticated user, then link with given credentials.
        // Otherwise, sign in using given credentials.
        if Auth.auth().currentUser != nil {
            return try await authLink(credentials: credentials)
        } else {
            return try await authSignIn(credentials: credentials)
        }
    }
    
    /// Authenticate with Firebase using Google `idToken`, and `accessToken` from given `GIDGoogleUser`.
    /// - Parameter user: Signed-in Google user.
    /// - Returns: Auth data.
    func googleAuth(_ user: GIDGoogleUser) async throws -> AuthDataResult? {
        guard let idToken = user.idToken?.tokenString else { return nil }

        let credentials = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
        do {
            return try await authenticateUser(credentials: credentials)
        }
        catch {
            print("FirebaseAuthError: googleAuth(user:) failed. \(error)")
            throw error
        }
    }

    
    func appleAuth(
        _ appleIDCredential: ASAuthorizationAppleIDCredential,
        nonce: String?
    ) async throws -> AuthDataResult? {
        guard let nonce = nonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }

        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            return nil
        }

        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            return nil
        }

        // Initialize a Firebase credential, including the user's full name.
        let credentials = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                       rawNonce: nonce,
                                                       fullName: appleIDCredential.fullName)

        do {
            return try await authenticateUser(credentials: credentials)
        }
        catch {
            print("FirebaseAuthError: appleAuth(appleIDCredential:nonce:) failed. \(error)")
            throw error
        }
    }

    // MARK: - Sign-in

    private func authSignIn(credentials: AuthCredential) async throws -> AuthDataResult? {
        do {
            let result = try await Auth.auth().signIn(with: credentials)
            updateState(user: result.user)
            return result
        }
        catch {
            print("FirebaseAuthError: signIn(with:) failed. \(error)")
            throw error
        }
    }
    
    private func authLink(credentials: AuthCredential) async throws -> AuthDataResult? {
        do {
            guard let user = Auth.auth().currentUser else { return nil }
            let result = try await user.link(with: credentials)

            await updateDisplayName(for: result.user)
            updateState(user: result.user)

            return result
        }
        catch {
            print("FirebaseAuthError: link(with:) failed, \(error)")
            if let error = error as NSError? {
                if let code = AuthErrorCode.Code(rawValue: error.code), 
                    authLinkErrors.contains(code) {

                    // If provider is "apple.com", get updated AppleID credentials from the error object.
                    let appleCredentials =
                        credentials.provider == "apple.com"
                        ? error.userInfo[AuthErrorUserInfoUpdatedCredentialKey] as? AuthCredential
                        : nil

                    return try await self.authSignIn(credentials: appleCredentials ?? credentials)
                }
            }
            throw error
        }
    }

    /// Check if user's displayName is null or empty,
    /// then update using displayName from dataProvider.
    /// - Parameter user: Firebase auth user.
    private func updateDisplayName(for user: User) async {
        if let currentDisplayName = Auth.auth().currentUser?.displayName, !currentDisplayName.isEmpty {
            // current user is non-empty, don't overwrite it
        } else  {
            let displayName = user.providerData.first?.displayName
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            do {
                try await changeRequest.commitChanges()
            }
            catch {
                print("FirebaseAuthError: Failed to update the user's displayName. \(error.localizedDescription)")
            }
        }
    }

    @discardableResult
    func signInAnonymously() async throws -> AuthDataResult? {
        do {
            let result = try await Auth.auth().signInAnonymously()
            self.authState = .authenticated
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
        let providers = user.providerData
            .map { $0.providerID }.joined(separator: ", ")

        if providers.contains("apple.com")  {
            // TODO: Sign out from Apple
        }
        if providers.contains("google.com") {
            GoogleSignInManager.shared.signOutFromGoogle()
        }
    }

    /// Sign out current `Firebase` auth user
    func signOut() async throws {
        if let user = Auth.auth().currentUser {

            // Sign out current authenticated user in Firebase
            do {
                firebaseProviderSignOut(user)
                try Auth.auth().signOut()
                self.authState = .signedOut
            }
            catch let error as NSError {
                print("FirebaseAuthError: failed to sign out from Firebase, \(error)")
                throw error
            }
        }
    }
}

