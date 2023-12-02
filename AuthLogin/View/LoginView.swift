//
//  LoginView.swift
//  AuthLogin
//
//  Created by Marwa Abou Niaaj on 29/11/2023.
//

import AuthenticationServices
import GoogleSignInSwift
import SwiftUI

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                Image("loginScreen")
                    .foregroundStyle(Color(.loginBlue))
                    .padding()
                Spacer()

                // MARK: - Apple
                SignInWithAppleButton(
                    onRequest: { request in
                        AppleSignInManager.shared.requestAppleAuthorization(request)
                    },
                    onCompletion: { result in
                        handleAppleID(result)
                    }
                )
                .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                .frame(width: 280, height: 45, alignment: .center)

                // MARK: - Google
                GoogleSignInButton {
                    signInWithGoogle()
                }
                .frame(width: 280, height: 45, alignment: .center)

                // MARK: - Anonymous
                // Hide `Skip` button if user is anonymous.
                if authManager.authState == .signedOut {
                    Button {
                        signAnonymously()
                    } label: {
                        Text("Skip")
                            .font(.body.bold())
                            .frame(width: 280, height: 45, alignment: .center)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.loginYellow))
        }
    }

    /// Sign in with `Google`, and authenticate with `Firebase`.
    func signInWithGoogle() {
        GoogleSignInManager.shared.signInWithGoogle { user, error in
            if let error = error {
                print("GoogleSignInError: failed to sign in with Google, \(error))")
                // Here you can show error message to user.
                return
            }

            guard let user = user else { return }
            Task {
                do {
                    let result = try await authManager.googleAuth(user)
                    if let result = result {
                        print("GoogleSignInSuccess: \(result.user.uid)")
                        dismiss()
                    }
                }
                catch {
                    print("GoogleSignInError: failed to authenticate with Google, \(error))")
                    // Here you can show error message to user.
                }
            }
        }
    }

    func handleAppleID(_ result: Result<ASAuthorization, Error>) {
        if case let .success(auth) = result {
            guard let appleIDCredentials = auth.credential as? ASAuthorizationAppleIDCredential else {
                print("AppleAuthorization failed: AppleID credential not available")
                return
            }

            Task {
                do {
                    let result = try await authManager.appleAuth(
                        appleIDCredentials, 
                        nonce: AppleSignInManager.nonce
                    )
                    if let result = result {
                        dismiss()
                    }
                } catch {
                    print("AppleAuthorization failed: \(error)")
                    // Here you can show error message to user.
                }
            }
        } 
        else if case let .failure(error) = result {
            print("AppleAuthorization failed: \(error)")
            // Here you can show error message to user.
        }
    }

    /// Sign-in anonymously
    func signAnonymously() {
        Task {
            do {
                let result = try await authManager.signInAnonymously()
                print("SignInAnonymouslySuccess: \(result?.user.uid ?? "N/A")")
            }
            catch {
                print("SignInAnonymouslyError: \(error)")
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
