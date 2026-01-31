//
//  ContentView.swift
//  HamaraPrayas_build
//
//  Created by Avighna Daruka on 29/08/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    @State private var isFirebaseReady = false
    
    var body: some View {
        Group {
            if isFirebaseReady {
                if authService.isAuthenticated {
                    MainTabView()
                        .environmentObject(authService)
                        .onAppear {
                            print("🎯 MainTabView appeared - User authenticated")
                        }
                } else {
                    LoginView()
                        .environmentObject(authService)
                        .onAppear {
                            print("🔐 LoginView appeared - User not authenticated")
                        }
                }
            } else {
                // Show loading screen while Firebase initializes
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Initializing...")
                        .font(.headline)
                        .padding(.top)
                }
            }
        }
        .onAppear {
            // Ensure Firebase is ready before proceeding
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFirebaseReady = true
                print("App launched - Authentication status: \(authService.isAuthenticated)")
            }
        }
    }
}

#Preview {
    ContentView()
}
