import SwiftUI

struct SplashView: View {
    @Binding var isShowingSplash: Bool

    @State private var isVisible = true
    @State private var bgPhase: Double = 0
    @State private var grainsAppeared = false
    @State private var logoAppeared = false
    @State private var logoScale: CGFloat = 0.4
    @State private var titleOpacity: Double = 0
    @State private var glowPulse: Double = 0
    @State private var sunRotation: Double = 0
    @State private var exiting = false

    // Falling grain particles
    private struct Grain: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let duration: Double
        let size: CGFloat
        let rotation: Double
    }
    private let grains: [Grain] = (0..<14).map { i in
        Grain(
            x: CGFloat.random(in: 0.05...0.95),
            delay: Double(i) * 0.08,
            duration: Double.random(in: 1.4...2.2),
            size: CGFloat.random(in: 6...12),
            rotation: Double.random(in: -180...180)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Layer 1 — animated background gradient
                LinearGradient(
                    colors: bgColors(for: bgPhase),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Layer 2 — sun glow behind logo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.grainGlow.opacity(0.6), AppTheme.grain.opacity(0.0)],
                            center: .center, startRadius: 0, endRadius: 220
                        )
                    )
                    .frame(width: 440, height: 440)
                    .scaleEffect(0.6 + glowPulse * 0.25)
                    .opacity(0.5 + glowPulse * 0.5)

                // Layer 3 — falling grain particles (thematic)
                ForEach(grains) { grain in
                    GrainShape()
                        .fill(AppTheme.grain)
                        .frame(width: grain.size, height: grain.size * 1.4)
                        .rotationEffect(.degrees(grainsAppeared ? grain.rotation + 360 : grain.rotation))
                        .position(
                            x: grain.x * geo.size.width,
                            y: grainsAppeared ? geo.size.height + 30 : -30
                        )
                        .opacity(grainsAppeared ? 0.8 : 0)
                        .animation(
                            .linear(duration: grain.duration)
                                .repeatForever(autoreverses: false)
                                .delay(grain.delay),
                            value: grainsAppeared
                        )
                }

                // Layer 4 — rotating sun rays behind logo
                ZStack {
                    ForEach(0..<8) { i in
                        Capsule()
                            .fill(AppTheme.grainGlow.opacity(0.45))
                            .frame(width: 6, height: 60)
                            .offset(y: -78)
                            .rotationEffect(.degrees(Double(i) * 45 + sunRotation))
                    }
                }
                .opacity(logoAppeared ? 0.9 : 0)
                .scaleEffect(logoAppeared ? 1.0 : 0.4)

                // Layer 5 — logo (chicken + grain icon, hand-drawn)
                VStack(spacing: 18) {
                    LogoMark()
                        .frame(width: 140, height: 140)
                        .scaleEffect(exiting ? 1.4 : logoScale)
                        .opacity(exiting ? 0 : (logoAppeared ? 1 : 0))

                    VStack(spacing: 6) {
                        Text("Feed Poultry")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(AppTheme.earthDark)
                        Text("Optimize your feed")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.earth)
                            .tracking(1.2)
                    }
                    .opacity(titleOpacity)
                    .opacity(exiting ? 0 : 1)
                }
            }
        }
        .onAppear { runIntro() }
        .onDisappear { stopAllAnimations() }
    }

    private func bgColors(for phase: Double) -> [Color] {
        let blend = (sin(phase) + 1) / 2
        return [
            AppTheme.bgPrimary.blend(with: AppTheme.bgSoft, t: blend),
            AppTheme.bgSoft.blend(with: AppTheme.bgGrain, t: blend)
        ]
    }

    private func runIntro() {
        guard isVisible else { return }

        // Phase 1 (0–0.6s): background drift + grains
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: true)) {
            bgPhase = .pi
        }
        withAnimation(.easeOut(duration: 0.5)) {
            grainsAppeared = true
        }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            glowPulse = 1
        }
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            sunRotation = 360
        }

        // Phase 2 (0.6–1.4s): logo enters with spring
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            guard isVisible else { return }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) {
                logoAppeared = true
                logoScale = 1.0
            }
        }

        // Phase 3 (1.4–2.2s): title fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            guard isVisible else { return }
            withAnimation(.easeOut(duration: 0.6)) {
                titleOpacity = 1
            }
        }

        // Phase 4 (2.2–2.5s): exit transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.55) {
            guard isVisible else { return }
            withAnimation(.easeIn(duration: 0.5)) {
                exiting = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                isShowingSplash = false
            }
        }
    }

    private func stopAllAnimations() {
        isVisible = false
        // Reset all looping animation state to halt repeats
        withAnimation(.linear(duration: 0)) {
            bgPhase = 0
            grainsAppeared = false
            glowPulse = 0
            sunRotation = 0
        }
    }
}

// MARK: - Logo (custom chicken + grain mark)

private struct LogoMark: View {
    var body: some View {
        ZStack {
            // Plate / nest
            Circle()
                .fill(AppTheme.cardWhite)
                .shadow(color: AppTheme.softShadow, radius: 12, y: 6)

            Circle()
                .stroke(AppTheme.divider, lineWidth: 2)
                .padding(6)

            // Chicken body
            ZStack {
                Ellipse()
                    .fill(AppTheme.birdWarm)
                    .frame(width: 72, height: 60)
                    .offset(x: 4, y: 8)
                // Head
                Circle()
                    .fill(AppTheme.birdWarm)
                    .frame(width: 38, height: 38)
                    .offset(x: 28, y: -8)
                // Comb
                ZStack {
                    Circle().fill(AppTheme.statusBad).frame(width: 12, height: 12).offset(x: 22, y: -28)
                    Circle().fill(AppTheme.statusBad).frame(width: 14, height: 14).offset(x: 30, y: -30)
                    Circle().fill(AppTheme.statusBad).frame(width: 11, height: 11).offset(x: 38, y: -28)
                }
                // Beak
                Triangle()
                    .fill(AppTheme.earthSoft)
                    .frame(width: 12, height: 9)
                    .offset(x: 50, y: -8)
                // Eye
                Circle().fill(AppTheme.earthDark).frame(width: 5, height: 5).offset(x: 32, y: -10)
                // Wing
                Ellipse().fill(AppTheme.earthSoft.opacity(0.7))
                    .frame(width: 30, height: 22)
                    .offset(x: 0, y: 10)
                // Legs
                Capsule().fill(AppTheme.earthSoft)
                    .frame(width: 4, height: 16).offset(x: -4, y: 38)
                Capsule().fill(AppTheme.earthSoft)
                    .frame(width: 4, height: 16).offset(x: 14, y: 38)
            }
            // Grain near beak
            VStack(spacing: 2) {
                GrainShape().fill(AppTheme.grainActive).frame(width: 8, height: 11)
                GrainShape().fill(AppTheme.grain).frame(width: 6, height: 9)
            }
            .offset(x: 56, y: 6)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct GrainShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.insetBy(dx: 0, dy: 0)
        p.addEllipse(in: r)
        return p
    }
}

private extension Color {
    func blend(with other: Color, t: Double) -> Color {
        let u = max(0, min(1, t))
        let a = UIColor(self).cgColor.components ?? [1, 1, 1, 1]
        let b = UIColor(other).cgColor.components ?? [1, 1, 1, 1]
        let r = a[0] * (1 - u) + b[0] * u
        let g = a[1] * (1 - u) + b[1] * u
        let bl = a[2] * (1 - u) + b[2] * u
        return Color(red: r, green: g, blue: bl)
    }
}
