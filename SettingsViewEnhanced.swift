//
//  SettingsViewEnhanced.swift
//  r2rscorecards
//
//  Created by PSL on 06/03/2026
//

import SwiftUI

struct SettingsViewEnhanced: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var themeManager: ThemeManager // ✨ THEME MANAGER
    
    // Personalization
    @AppStorage("preferredCornerColor") private var preferredCornerColor = "none"
    @AppStorage("showPunchStats") private var showPunchStats = true
    @AppStorage("autoSubmitScorecard") private var autoSubmitScorecard = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    
    // Display
    @AppStorage("useLargeText") private var useLargeText = false
    @AppStorage("showRoundTimer") private var showRoundTimer = true
    @AppStorage("colorScheme") private var colorScheme = "system"
    
    // Scoring
    @AppStorage("defaultScoringSystem") private var defaultScoringSystem = "10point"
    @AppStorage("enableSwipeScoring") private var enableSwipeScoring = true
    @AppStorage("confirmBeforeSubmit") private var confirmBeforeSubmit = true
    
    @State private var showResetAlert = false
    @State private var showSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                profileSection
                themeSection // ✨ NEW THEME SECTION
                personalizationSection
                scoringSection
                displaySection
                notificationSection
                tipJarSection // ✨ TIP JAR
                dataPrivacySection
                aboutSection
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Reset Settings", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetSettings()
                }
            } message: {
                Text("This will reset all your preferences to default values.")
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    // Sign out logic here
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    // MARK: - Sections
    
    private var themeSection: some View {
        Section {
            Picker("App Theme", selection: $themeManager.currentTheme) {
                ForEach(ThemeManager.AppTheme.allCases, id: \.self) { theme in
                    HStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: theme.primaryGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 20, height: 20)
                        Text(theme.rawValue)
                    }
                    .tag(theme)
                }
            }
            
            NavigationLink(destination: ThemePreviewView()) {
                Label("Preview Themes", systemImage: "paintpalette")
            }
        } header: {
            Text("Appearance")
        } footer: {
            Text("Choose a theme that matches your style. Changes apply immediately.")
        }
    }
    
    private var profileSection: some View {
        Section {
            if let name = auth.displayName, !name.isEmpty {
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        Text(name.prefix(2).uppercased())
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.headline)
                        Text("Local Account")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Sign In")
                            .font(.headline)
                        Text("Sync your scorecards")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Profile")
        }
    }
    
    private var personalizationSection: some View {
        Section {
            Picker("Favorite Corner", selection: $preferredCornerColor) {
                Text("None").tag("none")
                Text("Red Corner").tag("red")
                Text("Blue Corner").tag("blue")
            }
            
            Toggle("Show Punch Statistics", isOn: $showPunchStats)
            Toggle("Auto-Submit Scorecards", isOn: $autoSubmitScorecard)
        } header: {
            Text("Personalization")
        } footer: {
            Text("Customize your scoring experience.")
        }
    }
    
    private var scoringSection: some View {
        Section {
            Picker("Scoring System", selection: $defaultScoringSystem) {
                Text("10-Point Must").tag("10point")
                Text("Half Point").tag("halfpoint")
                Text("Custom").tag("custom")
            }
            
            Toggle("Swipe to Score", isOn: $enableSwipeScoring)
            Toggle("Confirm Before Submit", isOn: $confirmBeforeSubmit)
            
            NavigationLink(destination: ScoringGuideView()) {
                Label("Scoring Guide", systemImage: "book.fill")
            }
        } header: {
            Text("Scoring Preferences")
        } footer: {
            if enableSwipeScoring {
                Text("Swipe right for red corner, left for blue corner.")
            }
        }
    }
    
    private var displaySection: some View {
        Section {
            Picker("Appearance", selection: $colorScheme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            
            Toggle("Large Text Mode", isOn: $useLargeText)
            Toggle("Show Round Timer", isOn: $showRoundTimer)
        } header: {
            Text("Display")
        }
    }
    
    private var notificationSection: some View {
        Section {
            Toggle("Notifications", isOn: $notificationsEnabled)
            Toggle("Sound Effects", isOn: $soundEffectsEnabled)
            Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
        } header: {
            Text("Notifications & Sounds")
        }
    }
    
    private var tipJarSection: some View {
        Section {
            NavigationLink(destination: TipJarView()) {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.title3)
                        .foregroundStyle(.pink)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Support Development")
                            .font(.headline)
                        Text("Buy me a coffee and support the app!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("❤️ Support")
        } footer: {
            Text("This app is free! Tips help me keep it running and add new features.")
        }
    }
    
    private var dataPrivacySection: some View {
        Section {
            NavigationLink(destination: PrivacyFAQView()) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }
            
            if auth.currentUserIdentifier != nil {
                Button(role: .destructive) {
                    showSignOutAlert = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.red)
                }
            }
            
            Button {
                showResetAlert = true
            } label: {
                Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                    .foregroundStyle(.orange)
            }
        } header: {
            Text("Data & Privacy")
        }
    }
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            
            NavigationLink(destination: WhatsNewView()) {
                Label("What's New", systemImage: "sparkles")
            }
            
            Button {
                shareApp()
            } label: {
                Label("Share App", systemImage: "square.and.arrow.up")
            }
        } header: {
            Text("About")
        } footer: {
            VStack(alignment: .center, spacing: 4) {
                Text("R2R Scorecards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Made with ❤️ for boxing fans")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Actions
    
    private func resetSettings() {
        preferredCornerColor = "none"
        showPunchStats = true
        autoSubmitScorecard = false
        notificationsEnabled = true
        soundEffectsEnabled = true
        hapticFeedbackEnabled = true
        useLargeText = false
        showRoundTimer = true
        colorScheme = "system"
        defaultScoringSystem = "10point"
        enableSwipeScoring = true
        confirmBeforeSubmit = true
    }
    
    private func shareApp() {
        // Share logic
    }
}

// MARK: - Supporting Views

struct ScoringGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Scoring Guide")
                    .font(.largeTitle.bold())
                
                Text("Learn how to score fights like a professional judge.")
                    .foregroundStyle(.secondary)
                
                guideSection(
                    title: "10-Point Must System",
                    description: "The most common scoring system. The winner of each round receives 10 points, the loser 9 or less."
                )
                
                guideSection(
                    title: "Knockdowns",
                    description: "A knockdown typically results in a 10-8 round. Multiple knockdowns can lead to 10-7 or lower."
                )
                
                guideSection(
                    title: "Even Rounds",
                    description: "In very close rounds, judges may score it 10-10, though this is rare."
                )
            }
            .padding()
        }
        .navigationTitle("Scoring Guide")
    }
    
    private func guideSection(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(description)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WhatsNewView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("What's New")
                    .font(.largeTitle.bold())
                
                changelogItem(
                    version: "1.0.0",
                    date: "March 2026",
                    changes: [
                        "✨ All-new beautiful interface",
                        "🎨 Personalization options",
                        "👥 Enhanced friend groups",
                        "📊 Improved statistics",
                        "🔄 Better sync performance"
                    ]
                )
            }
            .padding()
        }
        .navigationTitle("What's New")
    }
    
    private func changelogItem(version: String, date: String, changes: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Version \(version)")
                    .font(.headline)
                Spacer()
                Text(date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(changes, id: \.self) { change in
                Text(change)
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Theme Preview View

struct ThemePreviewView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(ThemeManager.AppTheme.allCases, id: \.self) { theme in
                    ThemePreviewCard(theme: theme, isSelected: themeManager.currentTheme == theme) {
                        themeManager.applyTheme(theme)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Choose Theme")
        .themedBackground(themeManager.currentTheme)
    }
}

struct ThemePreviewCard: View {
    let theme: ThemeManager.AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 16) {
                // Theme colors preview
                HStack(spacing: 12) {
                    ForEach(theme.primaryGradient, id: \.description) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 40, height: 40)
                    }
                }
                
                // Theme name
                Text(theme.rawValue)
                    .font(.headline)
                
                // Theme description
                Text(themeDescription(for: theme))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Selected indicator
                if isSelected {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Active")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(isSelected ? 0.2 : 0.1), radius: isSelected ? 12 : 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: isSelected ? theme.primaryGradient : [.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 3 : 0
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func themeDescription(for theme: ThemeManager.AppTheme) -> String {
        switch theme {
        case .default: return "Classic red and orange design"
        case .dark: return "Perfect for late-night scoring"
        case .light: return "Clean and bright interface"
        case .boxing: return "Traditional boxing ring aesthetic"
        case .neon: return "Vibrant and modern"
        }
    }
}

#Preview {
    SettingsViewEnhanced()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
}
