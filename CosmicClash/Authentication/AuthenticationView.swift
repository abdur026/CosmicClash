//
//  AuthenticationView.swift
//  CosmicClash
//
//  Created by Abdur Rehman on 8/21/23.
//


import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

import Foundation

@MainActor
final class AuthenticationViewModel: ObservableObject {
        
    
    func signInGoogle() async throws {
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()
        _ = try await AuthenticationManager.shared.signInWithGoogle(tokens: tokens)
        
    }

}

struct AuthenticationView: View {
    
    @StateObject private var viewModel = AuthenticationViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        VStack {
            
            NavigationLink {
                SignInEmailView(showSignInView: $showSignInView)
            } label: {
                HStack {
                    Image(systemName: "envelope.fill")
                        .font(.title)
                        .foregroundColor(.white)
                    Text("Sign In With Email")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
            }
            
            GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                Task {
                    do {
                        try await viewModel.signInGoogle()
                        showSignInView = false
                    } catch {
                        print(error)
                    }
                }
            }


            Spacer()
        }
        .padding()
        .navigationTitle("Sign In")
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AuthenticationView(showSignInView: .constant(false))
        }
    }
}
