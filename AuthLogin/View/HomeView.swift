//
//  HomeView.swift
//  AuthLogin
//
//  Created by Marwa Abou Niaaj on 29/11/2023.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLoginSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading) {
                    if authManager.isAuthenticatedUser && !authManager.isAnonymous {
                        Text("Name placeholder")
                            .font(.headline)

                        Text("Email placeholder")
                            .font(.subheadline)
                    }
                    else {
                        Text("Sign-in to view data!")
                            .font(.headline)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding()


                Spacer()
                Image("homeScreen")
                    .foregroundStyle(Color(.loginBlue))
                    .padding()
                Spacer()

                // Show `Sign out` iff user is not anonymous,
                // otherwise show `Sign-in` to present LoginView() when tapped.
                Button {
                    if authManager.isAnonymous {
                        showLoginSheet = true
                    } else {
                        signOut()
                    }
                } label: {
                    Text(authManager.isAnonymous ? "Sign-in" :"Sign out")
                        .font(.body.bold())
                        .frame(width: 120, height: 45, alignment: .center)
                        .foregroundStyle(Color(.loginYellow))
                        .background(Color(.loginBlue))
                        .cornerRadius(10)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.loginYellow))
            .navigationTitle("Welcome")

            .sheet(isPresented: $showLoginSheet) {
                LoginView()
            }
        }
    }

    func signOut() {
        Task {
            do {
                try await authManager.signOut()
            }
            catch {
                print("Error: \(error)")
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager())
}
