//
//  LoginView.swift
//  AuthLogin
//
//  Created by Marwa Abou Niaaj on 29/11/2023.
//

import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

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
                        // TODO: Request Apple Authorization
                    },
                    onCompletion: { result in
                        // TODO: Handle AppleID Completion
                    }
                )
                .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                .frame(width: 280, height: 45, alignment: .center)

                // MARK: - Google
                /*
                GoogleSignInButton {
                    // TODO: Sign-in with Google
                }
                .frame(width: 280, height: 45, alignment: .center)
                 */

                // MARK: - Anonymous
                Button {
                    // TODO: Sign-in Anonymously
                } label: {
                    Text("Skip")
                        .font(.body.bold())
                        .frame(width: 280, height: 45, alignment: .center)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.loginYellow))
        }
    }
}

#Preview {
    LoginView()
}
