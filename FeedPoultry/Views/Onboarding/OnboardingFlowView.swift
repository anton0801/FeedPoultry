import SwiftUI

struct OnboardingFlowView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var page: Int = 0

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Spacer()
                    Button("Skip") {
                        withAnimation(.easeInOut) { hasCompletedOnboarding = true }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                // Pages
                TabView(selection: $page) {
                    OnboardingPage1().tag(0)
                    OnboardingPage2().tag(1)
                    OnboardingPage3().tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: page)

                // Indicator + button
                VStack(spacing: 18) {
                    HStack(spacing: 8) {
                        ForEach(0..<3) { i in
                            Capsule()
                                .fill(i == page ? AppTheme.grainActive : AppTheme.divider.opacity(0.6))
                                .frame(width: i == page ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                        }
                    }
                    PrimaryButton(title: page < 2 ? "Next" : "Get Started",
                                  icon: page < 2 ? "arrow.right" : "checkmark") {
                        if page < 2 {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { page += 1 }
                        } else {
                            withAnimation(.easeInOut) { hasCompletedOnboarding = true }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Page 1 — Tap to feed (tap-to-trigger animation)

private struct OnboardingPage1: View {
    @State private var burst: Bool = false
    @State private var ringScale: CGFloat = 0.6
    @State private var taps: Int = 0
    @State private var isVisible = true
    @State private var bobbing = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 12)
            ZStack {
                // Ground ring
                Circle()
                    .fill(AppTheme.bgSoft)
                    .frame(width: 240, height: 240)
                Circle()
                    .stroke(AppTheme.divider, lineWidth: 2)
                    .frame(width: 240, height: 240)
                    .scaleEffect(ringScale)
                    .opacity(burst ? 0 : 0.7)

                // Burst grains
                ForEach(0..<10) { i in
                    GrainShape()
                        .fill(AppTheme.grainActive)
                        .frame(width: 10, height: 14)
                        .offset(burst ? CGSize(
                            width: cos(Double(i) * .pi / 5) * 110,
                            height: sin(Double(i) * .pi / 5) * 110
                        ) : .zero)
                        .opacity(burst ? 0 : 1)
                        .rotationEffect(.degrees(burst ? Double(i) * 36 + 180 : 0))
                }

                // Chicken
                ChickenIllustration()
                    .frame(width: 180, height: 180)
                    .offset(y: bobbing ? -6 : 0)
                    .scaleEffect(burst ? 1.05 : 1.0)
            }
            .frame(height: 280)
            .contentShape(Rectangle())
            .onTapGesture { fire() }
            .onAppear {
                isVisible = true
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    bobbing = true
                }
            }
            .onDisappear {
                isVisible = false
                bobbing = false
            }

            VStack(spacing: 10) {
                Text("Choose Bird Type")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Tap the chicken to feed it.\nWe support chickens, ducks and quail.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textMuted)
                    .padding(.horizontal, 30)
                if taps > 0 {
                    Text("Fed \(taps) time\(taps == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.health)
                }
            }
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 24)
    }

    private func fire() {
        taps += 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
            burst = true
            ringScale = 1.4
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            burst = false
            ringScale = 0.6
        }
    }
}

// MARK: - Page 2 — Drag to mix (drag gesture)

private struct OnboardingPage2: View {
    @State private var dragOffset: CGSize = .zero
    @State private var dropped: Bool = false
    @State private var bowlGlow: Bool = false
    @State private var isVisible = true

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 12)
            ZStack {
                // Bowl
                ZStack {
                    Ellipse()
                        .fill(AppTheme.cardWhite)
                        .frame(width: 220, height: 100)
                        .shadow(color: AppTheme.softShadow, radius: 6, y: 4)
                    Ellipse()
                        .stroke(AppTheme.divider, lineWidth: 2)
                        .frame(width: 220, height: 100)

                    // Mixed grain piles
                    HStack(spacing: -10) {
                        Circle().fill(AppTheme.grain).frame(width: 28, height: 28)
                        Circle().fill(AppTheme.grainActive).frame(width: 32, height: 32)
                        Circle().fill(AppTheme.earthSoft).frame(width: 26, height: 26)
                    }
                    .opacity(dropped ? 1 : 0.5)
                    .scaleEffect(dropped ? 1.08 : 1.0)

                    Ellipse()
                        .stroke(AppTheme.healthSoft, lineWidth: 4)
                        .frame(width: 240, height: 120)
                        .opacity(bowlGlow ? 0 : 0.8)
                        .scaleEffect(bowlGlow ? 1.4 : 1.0)
                }
                .offset(y: 80)

                // Draggable grain bag
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.grainGradient)
                        .frame(width: 90, height: 110)
                        .shadow(color: AppTheme.yellowGlow, radius: 12, y: 6)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(AppTheme.earthDark)
                }
                .offset(x: dragOffset.width, y: -60 + dragOffset.height)
                .gesture(
                    DragGesture()
                        .onChanged { v in dragOffset = v.translation }
                        .onEnded { v in
                            // Drop check: if dragged down enough, register a mix
                            if v.translation.height > 80 {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                    dropped = true
                                    bowlGlow = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    bowlGlow = false
                                }
                            }
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                                dragOffset = .zero
                            }
                        }
                )
            }
            .frame(height: 280)
            .onAppear { isVisible = true }
            .onDisappear {
                isVisible = false
                dragOffset = .zero
                dropped = false
                bowlGlow = false
            }

            VStack(spacing: 10) {
                Text("Mix the Right Feed")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Drag the bag down into the bowl to mix.\nWe'll calculate the perfect ratio.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textMuted)
                    .padding(.horizontal, 24)
            }
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Page 3 — Scroll-driven productivity chart (scroll animation)

private struct OnboardingPage3: View {
    @State private var animateBars: Bool = false
    @State private var pulse: Bool = false
    @State private var isVisible = true

    private let values: [CGFloat] = [0.35, 0.55, 0.42, 0.7, 0.85, 0.95]

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 12)
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.cardWhite)
                    .frame(width: 280, height: 220)
                    .shadow(color: AppTheme.softShadow, radius: 10, y: 6)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Productivity")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .bold))
                            Text("+38%")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(AppTheme.health)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(AppTheme.health.opacity(0.15)))
                    }
                    HStack(alignment: .bottom, spacing: 10) {
                        ForEach(0..<values.count, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(i == values.count - 1 ? AppTheme.healthGradient : AppTheme.grainGradient)
                                .frame(width: 26, height: animateBars ? 130 * values[i] : 6)
                                .animation(
                                    .spring(response: 0.7, dampingFraction: 0.7).delay(Double(i) * 0.08),
                                    value: animateBars
                                )
                        }
                    }
                    .frame(height: 140)
                }
                .padding(20)
                .frame(width: 280, height: 220, alignment: .topLeading)

                // Pulsing badge
                ZStack {
                    Circle().fill(AppTheme.health).frame(width: 36, height: 36)
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                }
                .offset(x: 120, y: -90)
                .scaleEffect(pulse ? 1.15 : 1.0)
            }
            .onAppear {
                isVisible = true
                withAnimation(.easeOut(duration: 0.8).delay(0.15)) {
                    animateBars = true
                }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            .onDisappear {
                isVisible = false
                animateBars = false
                pulse = false
            }

            VStack(spacing: 10) {
                Text("Improve Productivity")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Track growth, eggs and health.\nSee what your flock needs to thrive.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textMuted)
                    .padding(.horizontal, 28)
            }
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Chicken illustration (used by page 1)

struct ChickenIllustration: View {
    var body: some View {
        ZStack {
            Circle().fill(AppTheme.cardWhite).shadow(color: AppTheme.softShadow, radius: 8, y: 4)
            ZStack {
                Ellipse().fill(AppTheme.birdWarm).frame(width: 96, height: 80).offset(x: 6, y: 12)
                Circle().fill(AppTheme.birdWarm).frame(width: 50, height: 50).offset(x: 36, y: -10)
                ZStack {
                    Circle().fill(AppTheme.statusBad).frame(width: 14, height: 14).offset(x: 28, y: -36)
                    Circle().fill(AppTheme.statusBad).frame(width: 18, height: 18).offset(x: 38, y: -38)
                    Circle().fill(AppTheme.statusBad).frame(width: 14, height: 14).offset(x: 48, y: -36)
                }
                // Beak
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 8))
                    p.addLine(to: CGPoint(x: 18, y: 0))
                    p.addLine(to: CGPoint(x: 18, y: 16))
                    p.closeSubpath()
                }
                .fill(AppTheme.earthSoft)
                .frame(width: 18, height: 16)
                .offset(x: 60, y: -10)
                Circle().fill(AppTheme.earthDark).frame(width: 6, height: 6).offset(x: 42, y: -12)
                Ellipse().fill(AppTheme.earthSoft.opacity(0.7))
                    .frame(width: 38, height: 28).offset(x: 0, y: 14)
                Capsule().fill(AppTheme.earthSoft).frame(width: 5, height: 22).offset(x: -2, y: 50)
                Capsule().fill(AppTheme.earthSoft).frame(width: 5, height: 22).offset(x: 18, y: 50)
            }
        }
    }
}
