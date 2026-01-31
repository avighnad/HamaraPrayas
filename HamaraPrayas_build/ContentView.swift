//
//  ContentView.swift
//  HamaraPrayas_build
//
//  Created by Avighna Daruka on 29/08/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    @State private var isFirebaseReady = false
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var isCheckingAuth = true
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if isCheckingAuth {
                // Show splash screen while checking auth state
                SplashScreenView()
            } else if authService.isAuthenticated {
                // User is logged in
                if !hasCompletedOnboarding {
                    // Show onboarding for first-time users AFTER login
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                } else {
                    MainTabView()
                        .environmentObject(authService)
                        .onAppear {
                            print("🎯 MainTabView appeared - User authenticated")
                        }
                }
            } else {
                LoginView()
                    .environmentObject(authService)
                    .onAppear {
                        print("🔐 LoginView appeared - User not authenticated")
                    }
            }
        }
        .onAppear {
            checkAuthenticationState()
        }
        .onChange(of: authService.isAuthenticated) { _ in
            // When auth state changes, stop showing the loading screen
            if isCheckingAuth {
                isCheckingAuth = false
            }
        }
    }
    
    private func checkAuthenticationState() {
        // Check if there's already a logged-in user in Firebase
        if let currentUser = Auth.auth().currentUser {
            print("✅ Found existing Firebase user: \(currentUser.uid)")
            // User is already logged in, load their data
            authService.loadExistingUser(userId: currentUser.uid)
            
            // Give it a moment to load user data, then proceed
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isCheckingAuth = false
            }
        } else {
            print("❌ No existing Firebase user found")
            // No user logged in, go straight to login
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isCheckingAuth = false
            }
        }
    }
}

// MARK: - Splash Screen
struct SplashScreenView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.4), Color.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Logo
                Image("20250903_2341_White Heart Logo_remix_01k48rb1hyfyyvbkh2dcev5gza")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.5)
                
                VStack(spacing: 10) {
                    Text("Hamara Prayas")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("Blood Bank Locator & Info Services")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.top, 20)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ContentView()
}
