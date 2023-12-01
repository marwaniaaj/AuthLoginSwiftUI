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

    /// Sign in with `Google`.
    /// - Parameter completion: a block which is invoked when the restore/sign-in flow finishes.
    func signInWithGoogle(_ completion: @escaping GoogleAuthResult) {
        // Check previous sign-in.
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                completion(user, error)
            }
        } else {
            // Accessing rootViewController through shared instance of UIApplication.
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            guard let rootViewController = windowScene.windows.first?.rootViewController else { return }

            // Start sign-in flow
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                completion(result?.user, error)
            }
        }
    }
    
    /// Sign out from `Google`.
    func signOutFromGoogle() {
        GIDSignIn.sharedInstance.signOut()
    }
}
