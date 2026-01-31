//
//  OnboardingView.swift
//  HamaraPrayas_build
//
//  Created by Avighna Daruka on 31/01/26.
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "drop.fill",
            title: "Find Blood Banks",
            description: "Quickly locate nearby blood banks using your location. Get real-time information about blood availability and operating hours.",
            color: .red
        ),
        OnboardingPage(
            image: "heart.text.square.fill",
            title: "Request Blood",
            description: "Submit emergency blood requests and get notified when donors respond. Track your requests in real-time.",
            color: .pink
        ),
        OnboardingPage(
            image: "person.3.fill",
            title: "Join the Community",
            description: "Connect with blood donors in your area. Help save lives by responding to blood requests from people in need.",
            color: .orange
        ),
        OnboardingPage(
            image: "bell.badge.fill",
            title: "Stay Updated",
            description: "Receive notifications about urgent blood requests nearby. Be a hero when someone needs you the most.",
            color: .blue
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    pages[currentPage].color.opacity(0.3),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? pages[currentPage].color : Color.gray.opacity(0.3))
                            .frame(width: index == currentPage ? 12 : 8, height: index == currentPage ? 12 : 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 30)
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button(action: {
                            HapticManager.shared.lightImpact()
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(25)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            HapticManager.shared.lightImpact()
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            HapticManager.shared.success()
                            completeOnboarding()
                        }
                    }) {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            Image(systemName: currentPage < pages.count - 1 ? "chevron.right" : "arrow.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(pages[currentPage].color)
                        .cornerRadius(25)
                        .shadow(color: pages[currentPage].color.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
    
    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 180, height: 180)
                
                Circle()
                    .fill(page.color.opacity(0.25))
                    .frame(width: 140, height: 140)
                
                Image(systemName: page.image)
                    .font(.system(size: 70))
                    .foregroundColor(page.color)
            }
            .padding(.bottom, 20)
            
            // Title
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(5)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
