//
//  AuthenticationView.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftUI
import SwiftData
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App logo and title
                VStack(spacing: 15) {
                    Image(systemName: "graduationcap.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                    
                    Text("SHSAT Prepper")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Master the test, get into your dream school")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Features section
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(
                        icon: "checkmark.circle.fill",
                        title: "Personalized Practice",
                        description: "Questions tailored to your needs"
                    )
                    
                    FeatureRow(
                        icon: "chart.bar.fill",
                        title: "Performance Tracking",
                        description: "Monitor your progress over time"
                    )
                    
                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "Smart Recommendations",
                        description: "Focus on areas that need improvement"
                    )
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Sign in button
                VStack(spacing: 15) {
                    SignInWithAppleButton { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                authViewModel.signInWithApple(credential: appleIDCredential)
                            }
                        case .failure(let error):
                            print("Sign in with Apple failed: \(error.localizedDescription)")
                        }
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 50)
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
                    
                    Text("Your data is securely synced across devices")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 40)
            }
            
            // Loading overlay
            if case .signingIn = authViewModel.authState {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .background(Color.black.opacity(0.3))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Error alert
            if let errorMessage = authViewModel.errorMessage {
                VStack {
                    Text("Sign In Error")
                        .font(.headline)
                    
                    Text(errorMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("OK") {
                        // Reset error state
                        if case .error = authViewModel.authState {
                            authViewModel.authState = .signedOut
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 10)
                .padding(30)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    let environment = AppEnvironment.shared
    return AuthenticationView()
        .environmentObject(AuthViewModel(environment: environment))
}
