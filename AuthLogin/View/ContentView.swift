//
//  ContentView.swift
//  AuthLogin
//
//  Created by Marwa Abou Niaaj on 29/11/2023.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false

    var body: some View {
        VStack {
            VStack(spacing: 16) {
                if isLoggedIn {
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
}
