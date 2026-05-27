import SwiftUI

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    @State private var pressed = false
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { pressed = false }
                action()
            }
        } label: {
            HStack(spacing: 10) {
                if let icon { Image(systemName: icon) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(AppTheme.earthDark)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.grainGradient)
            )
            .shadow(color: AppTheme.yellowGlow, radius: pressed ? 4 : 12, y: pressed ? 1 : 6)
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    @State private var pressed = false
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { pressed = false }
                action()
            }
        } label: {
            HStack(spacing: 10) {
                if let icon { Image(systemName: icon) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(AppTheme.earthDark)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.bgSoft)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.divider, lineWidth: 1)
            )
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

struct PillButton: View {
    let title: String
    var systemImage: String? = nil
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .foregroundColor(isSelected ? AppTheme.earthDark : AppTheme.textSecondary)
            .background(
                Capsule().fill(isSelected ? AppTheme.grain : AppTheme.cardWarm)
            )
            .overlay(
                Capsule().stroke(isSelected ? AppTheme.grainActive : AppTheme.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Stat tile

struct StatTile: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle(padding: 14)
    }
}

// MARK: - Nutrient bar

struct NutrientBar: View {
    let label: String
    let percent: Double
    let target: Double
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text(String(format: "%.1f%%", percent))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                Text("/ \(Int(target))%")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.bgSoft)
                    Capsule()
                        .fill(color)
                        .frame(width: max(6, min(geo.size.width, geo.size.width * CGFloat(percent / 100))))
                    // target marker
                    Rectangle()
                        .fill(AppTheme.earthDark.opacity(0.5))
                        .frame(width: 2, height: 12)
                        .offset(x: geo.size.width * CGFloat(target / 100) - 1, y: -1)
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - Empty state

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String

    init(icon: String, title: String, message: String) {
        self.icon = icon
        self.title = title
        self.message = message
    }

    init(icon: String, title: String, subtitle: String = "") {
        self.icon = icon
        self.title = title
        self.message = subtitle
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(AppTheme.bgSoft).frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(AppTheme.earth)
            }
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            if !message.isEmpty {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Custom text field

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboard: UIKeyboardType = .default
    var label: String? = nil

    init(placeholder: String, text: Binding<String>, icon: String? = nil, keyboard: UIKeyboardType = .default) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.keyboard = keyboard
        self.label = nil
    }

    init(label: String, text: Binding<String>, placeholder: String = "", icon: String? = nil, keyboard: UIKeyboardType = .default) {
        self.placeholder = placeholder.isEmpty ? label : placeholder
        self._text = text
        self.icon = icon
        self.keyboard = keyboard
        self.label = label
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
            }
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundColor(AppTheme.earth)
                        .frame(width: 22)
                }
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.cardWarm)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppTheme.divider, lineWidth: 1)
            )
        }
    }
}

// MARK: - Toolbar background

struct ScreenBackground: View {
    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()
            // Subtle grain pattern
            GeometryReader { geo in
                ForEach(0..<12) { i in
                    Circle()
                        .fill(AppTheme.divider.opacity(0.12))
                        .frame(width: CGFloat(20 + (i * 7) % 30),
                               height: CGFloat(20 + (i * 7) % 30))
                        .position(
                            x: CGFloat((Int(geo.size.width) * (i + 3)) % max(1, Int(geo.size.width))),
                            y: CGFloat((Int(geo.size.height) * (i + 7)) % max(1, Int(geo.size.height)))
                        )
                }
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Score gauge

struct BalanceGauge: View {
    let score: Int
    var color: Color {
        switch score {
        case 80...100: return AppTheme.statusGood
        case 50..<80: return AppTheme.statusWarning
        default: return AppTheme.statusBad
        }
    }
    var label: String {
        switch score {
        case 80...100: return "Balanced"
        case 50..<80: return "Acceptable"
        default: return "Off-target"
        }
    }
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.bgSoft, lineWidth: 12)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: score)
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(color)
            }
        }
        .frame(width: 110, height: 110)
    }
}
