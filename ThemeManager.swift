//
//  ThemeManager.swift
//  Centralized theme and personalization management
//

import SwiftUI
import Combine // ✨ NEEDED FOR ObservableObject

// MARK: - Theme Manager

@MainActor
final class ThemeManager: ObservableObject { // ✨ ObservableObject only, no @Observable
    @Published var currentTheme: AppTheme = .default
    @Published var accentColor: Color = .red
    @Published var useLargeText: Bool = false
    @Published var preferredCorner: CornerPreference = .none
    
    enum AppTheme: String, CaseIterable {
        case `default` = "Default"
        case dark = "Dark Mode"
        case light = "Light Mode"
        case boxing = "Boxing Ring"
        case neon = "Neon Lights"
        
        var colorScheme: ColorScheme? {
            switch self {
            case .default: return nil
            case .dark: return .dark
            case .light: return .light
            case .boxing: return .dark
            case .neon: return .dark
            }
        }
        
        var primaryGradient: [Color] {
            switch self {
            case .default: return [.red, .orange]
            case .dark: return [.gray, .black]
            case .light: return [.blue, .cyan]
            case .boxing: return [.red, .black]
            case .neon: return [.pink, .purple, .blue]
            }
        }
        
        var backgroundColors: [Color] {
            switch self {
            case .default: return [Color(.systemBackground), Color(.systemGray6)]
            case .dark: return [.black, Color(.systemGray6)]
            case .light: return [.white, Color(.systemGray6)]
            case .boxing: return [.black, Color(.systemGray)]
            case .neon: return [.black, Color.purple.opacity(0.2)]
            }
        }
    }
    
    enum CornerPreference: String, CaseIterable {
        case none = "None"
        case red = "Red Corner"
        case blue = "Blue Corner"
        
        var color: Color? {
            switch self {
            case .none: return nil
            case .red: return .red
            case .blue: return .blue
            }
        }
    }
    
    // Apply theme
    func applyTheme(_ theme: AppTheme) {
        currentTheme = theme
        // Update accent color based on theme
        switch theme {
        case .default: accentColor = .red
        case .dark: accentColor = .white
        case .light: accentColor = .blue
        case .boxing: accentColor = .red
        case .neon: accentColor = .pink
        }
    }
}

// MARK: - Custom View Modifiers

struct ThemedBackground: ViewModifier {
    let theme: ThemeManager.AppTheme
    
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: theme.backgroundColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

struct ThemedCard: ViewModifier {
    let theme: ThemeManager.AppTheme
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(cardColor)
                    .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
            )
    }
    
    private var cardColor: Color {
        switch theme {
        case .default, .light: return Color(.systemBackground)
        case .dark, .boxing: return Color(.systemGray6)
        case .neon: return Color.purple.opacity(0.2)
        }
    }
    
    private var shadowColor: Color {
        switch theme {
        case .neon: return .pink.opacity(0.3)
        default: return .black.opacity(0.1)
        }
    }
}

struct ThemedButton: ViewModifier {
    let theme: ThemeManager.AppTheme
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
    }
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .cornerRadius(12)
    }
    
    private var backgroundColor: LinearGradient {
        switch (style, theme) {
        case (.primary, _):
            return LinearGradient(
                colors: theme.primaryGradient,
                startPoint: .leading,
                endPoint: .trailing
            )
        case (.secondary, _):
            return LinearGradient(
                colors: [Color(.systemGray5)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case (.destructive, _):
            return LinearGradient(
                colors: [.red],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive: return .white
        case .secondary: return .primary
        }
    }
}

// MARK: - View Extensions

extension View {
    func themedBackground(_ theme: ThemeManager.AppTheme) -> some View {
        modifier(ThemedBackground(theme: theme))
    }
    
    func themedCard(_ theme: ThemeManager.AppTheme, cornerRadius: CGFloat = 12) -> some View {
        modifier(ThemedCard(theme: theme, cornerRadius: cornerRadius))
    }
    
    func themedButton(_ theme: ThemeManager.AppTheme, style: ThemedButton.ButtonStyle = .primary) -> some View {
        modifier(ThemedButton(theme: theme, style: style))
    }
}

// MARK: - Custom Colors

extension Color {
    static let redCorner = Color(red: 0.9, green: 0.2, blue: 0.2)
    static let blueCorner = Color(red: 0.2, green: 0.4, blue: 0.9)
    
    // Boxing app specific colors
    static let boxingRing = Color(red: 0.95, green: 0.95, blue: 0.85)
    static let canvas = Color(red: 0.9, green: 0.9, blue: 0.85)
    static let rope = Color(red: 0.8, green: 0.1, blue: 0.1)
}

// MARK: - Theme Selector View

struct ThemeSelectionView: View {
    @Binding var selectedTheme: ThemeManager.AppTheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ThemeManager.AppTheme.allCases, id: \.self) { theme in
                        Button {
                            selectedTheme = theme
                        } label: {
                            HStack {
                                // Theme preview
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                colors: theme.primaryGradient,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "figure.boxing")
                                        .foregroundStyle(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(theme.rawValue)
                                        .font(.headline)
                                    Text(themeDescription(theme))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedTheme == theme {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Choose Your Theme")
                } footer: {
                    Text("Select a theme that matches your style. You can change this anytime in settings.")
                }
            }
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func themeDescription(_ theme: ThemeManager.AppTheme) -> String {
        switch theme {
        case .default: return "Classic red and orange design"
        case .dark: return "Perfect for late-night scoring"
        case .light: return "Clean and bright interface"
        case .boxing: return "Traditional boxing ring aesthetic"
        case .neon: return "Vibrant and modern"
        }
    }
}

// MARK: - Personalization Summary View

struct PersonalizationSummaryView: View {
    @EnvironmentObject private var auth: AuthManager
    @AppStorage("preferredCornerColor") private var preferredCornerColor = "none"
    @AppStorage("currentTheme") private var currentTheme = "default"
    @State private var showThemeSelector = false
    
    var body: some View {
        List {
            Section {
                // Theme
                HStack {
                    Label("Theme", systemImage: "paintbrush.fill")
                    Spacer()
                    Text(currentThemeDisplay)
                        .foregroundStyle(.secondary)
                    Button {
                        showThemeSelector = true
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Favorite Corner
                Picker("Favorite Corner", selection: $preferredCornerColor) {
                    Text("None").tag("none")
                    Text("Red Corner").tag("red")
                    Text("Blue Corner").tag("blue")
                }
                
                // Display Name
                if let name = auth.displayName {
                    HStack {
                        Label("Display Name", systemImage: "person.fill")
                        Spacer()
                        Text(name)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Your Personalization")
            } footer: {
                Text("These settings help customize your experience.")
            }
            
            Section {
                NavigationLink(destination: ThemeSelectionView(selectedTheme: .constant(.default))) {
                    Label("Customize Theme", systemImage: "paintpalette")
                }
                
                NavigationLink(destination: Text("Notification Preferences")) {
                    Label("Notifications", systemImage: "bell.fill")
                }
                
                NavigationLink(destination: Text("Scoring Preferences")) {
                    Label("Scoring Settings", systemImage: "slider.horizontal.3")
                }
            } header: {
                Text("More Options")
            }
        }
        .navigationTitle("Personalization")
        .sheet(isPresented: $showThemeSelector) {
            ThemeSelectionView(selectedTheme: .constant(.default))
        }
    }
    
    private var currentThemeDisplay: String {
        ThemeManager.AppTheme(rawValue: currentTheme.capitalized)?.rawValue ?? "Default"
    }
}

#Preview("Theme Selection") {
    ThemeSelectionView(selectedTheme: .constant(.default))
}

#Preview("Personalization Summary") {
    NavigationStack {
        PersonalizationSummaryView()
    }
    .environmentObject(AuthManager())
}
