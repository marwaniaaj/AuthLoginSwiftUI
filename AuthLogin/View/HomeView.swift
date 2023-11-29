//
//  HomeView.swift
//  AuthLogin
//
//  Created by Marwa Abou Niaaj on 29/11/2023.
//

import SwiftUI

struct HomeView: View {
    @State private var isLoggedIn = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading) {
                    if isLoggedIn {
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

                Button {
                    //TODO: Sign in/out
                } label: {
                    Text(isLoggedIn ? "Sign out" : "Sign in")
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
        }
    }
}

#Preview {
    HomeView()
}
