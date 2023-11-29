//
//  ContentView.swift
//  AuthLogin
//
//  Created by Marwa Abou Niaaj on 29/11/2023.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack {
            VStack(spacing: 16) {
                if authManager.isAuthenticatedUser {
                    HomeView()
                } else {
                    LoginView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
