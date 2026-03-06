//
//  OnboardingFlow.swift
//  r2rscorecards
//
//  Created by PSL on 06/03/2026
//

import SwiftUI

// MARK: - Onboarding Coordinator

struct OnboardingFlow: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Binding var showAuthChoice: Bool
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "figure.boxing",
            iconColor: .red,
            title: "Score Every Round",
            description: "Track each round with professional scoring. See punch-by-punch action unfold.",
            gradient: [.red, .orange]
        ),
        OnboardingPage(
            icon: "person.3.fill",
            iconColor: .blue,
            title: "Compare with Friends",
            description: "Create groups, share scorecards, and see how your scoring stacks up.",
            gradient: [.blue, .purple]
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            iconColor: .green,
            title: "Crowd Insights",
            description: "See how fans around the world scored the fight. Demographics and trends.",
            gradient: [.green, .cyan]
        ),
        OnboardingPage(
            icon: "icloud.fill",
            iconColor: .purple,
            title: "Sync Everywhere",
            description: "Your scorecards sync across all your devices. Never lose a score.",
            gradient: [.purple, .pink]
        )
    ]
    
    var body: some View {
        ZStack {
            // Dynamic background
            LinearGradient(
                colors: pages[currentPage].gradient.map { $0.opacity(0.15) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            hasCompletedOnboarding = true
                            dismiss()
                        }
                        .foregroundStyle(.secondary)
                        .padding()
                    }
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Bottom buttons
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        // Last page - Get Started
                        Button {
                            hasCompletedOnboarding = true
                            showAuthChoice = true
                        } label: {
                            HStack {
                                Text("Get Started")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: pages[currentPage].gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .cornerRadius(16)
                        }
                        
                        Button {
                            hasCompletedOnboarding = true
                            dismiss()
                        } label: {
                            Text("Maybe Later")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        // Next button
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            HStack {
                                Text("Next")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: pages[currentPage].gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Models

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let gradient: [Color]
}

// MARK: - Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: page.iconColor.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: page.icon)
                    .font(.system(size: 70, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 60)
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Wrapper for App Integration

struct OnboardingWrapper: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showAuthChoice = false
    
    var body: some View {
        if hasCompletedOnboarding {
            EmptyView()
        } else {
            OnboardingFlow(showAuthChoice: $showAuthChoice)
                .sheet(isPresented: $showAuthChoice) {
                    SupabaseSignInView()
                }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlow(showAuthChoice: .constant(false))
}
