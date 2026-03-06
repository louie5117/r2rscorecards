//
//  AnimatedTransitions.swift
//  Smooth animations for the app
//

import SwiftUI

// MARK: - Custom Transitions

extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var scaleAndFade: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }
}

// MARK: - Animated Card Modifier

struct AnimatedCard: ViewModifier {
    @State private var isVisible = false
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func animatedCard(delay: Double = 0) -> some View {
        modifier(AnimatedCard(delay: delay))
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200 - 100)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Bounce Animation

struct BounceAnimation: ViewModifier {
    @State private var bouncing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(bouncing ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: bouncing)
            .onAppear {
                bouncing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    bouncing = false
                }
            }
    }
}

extension View {
    func bounceOnAppear() -> some View {
        modifier(BounceAnimation())
    }
}

// MARK: - Pulse Animation

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulse() -> some View {
        modifier(PulseAnimation())
    }
}

// MARK: - Slide In From Side

struct SlideInFromSide: ViewModifier {
    @State private var isVisible = false
    let edge: Edge
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: !isVisible ? (edge == .leading ? -100 : 100) : 0,
                y: !isVisible ? (edge == .top ? -100 : edge == .bottom ? 100 : 0) : 0
            )
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func slideIn(from edge: Edge, delay: Double = 0) -> some View {
        modifier(SlideInFromSide(edge: edge, delay: delay))
    }
}

// MARK: - Animated Button Style

struct AnimatedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == AnimatedButtonStyle {
    static var animated: AnimatedButtonStyle {
        AnimatedButtonStyle()
    }
}

// MARK: - Loading Shimmer View

struct LoadingShimmerView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 80)
                    .shimmer()
            }
        }
        .padding()
    }
}

// MARK: - Success Checkmark Animation

struct SuccessCheckmark: View {
    @State private var checkmarkProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.green, lineWidth: 3)
                .frame(width: 60, height: 60)
            
            Path { path in
                path.move(to: CGPoint(x: 20, y: 30))
                path.addLine(to: CGPoint(x: 28, y: 38))
                path.addLine(to: CGPoint(x: 42, y: 22))
            }
            .trim(from: 0, to: checkmarkProgress)
            .stroke(Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .frame(width: 60, height: 60)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                checkmarkProgress = 1
            }
        }
    }
}

// MARK: - Preview

#Preview("Animated Cards") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(0..<5) { index in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 80)
                    .overlay(Text("Card \(index + 1)"))
                    .animatedCard(delay: Double(index) * 0.1)
            }
        }
        .padding()
    }
}

#Preview("Success Checkmark") {
    SuccessCheckmark()
}
