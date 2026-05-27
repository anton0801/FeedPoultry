import SwiftUI

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b, a: Double
        switch s.count {
        case 6:
            r = Double((v & 0xFF0000) >> 16) / 255.0
            g = Double((v & 0x00FF00) >> 8)  / 255.0
            b = Double(v & 0x0000FF)         / 255.0
            a = 1.0
        case 8:
            r = Double((v & 0xFF000000) >> 24) / 255.0
            g = Double((v & 0x00FF0000) >> 16) / 255.0
            b = Double((v & 0x0000FF00) >> 8)  / 255.0
            a = Double(v & 0x000000FF)         / 255.0
        default:
            r = 1; g = 1; b = 1; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

enum AppTheme {
    // Backgrounds
    static let bgPrimary   = Color(hex: "FFFBEB")
    static let bgSoft      = Color(hex: "FEF3C7")
    static let bgGrain     = Color(hex: "FDE68A")
    static let cardWhite   = Color(hex: "FFFFFF")
    static let cardWarm    = Color(hex: "FFF7ED")
    static let divider     = Color(hex: "FCD34D")
    static let dividerStrong = Color(hex: "FBBF24")

    // Primary accent (grain)
    static let grain       = Color(hex: "FACC15")
    static let grainActive = Color(hex: "EAB308")
    static let grainGlow   = Color(hex: "FDE047")

    // Health
    static let health       = Color(hex: "22C55E")
    static let healthActive = Color(hex: "16A34A")
    static let healthSoft   = Color(hex: "4ADE80")

    // Earth
    static let earthDark   = Color(hex: "92400E")
    static let earth       = Color(hex: "B45309")
    static let earthSoft   = Color(hex: "D97706")

    // Bird accents
    static let birdWarm    = Color(hex: "F59E0B")
    static let birdSoft    = Color(hex: "FCD34D")

    // Status
    static let statusGood    = Color(hex: "22C55E")
    static let statusWarning = Color(hex: "FACC15")
    static let statusBad     = Color(hex: "EF4444")

    // Nutrients
    static let protein  = Color(hex: "3B82F6")
    static let fat      = Color(hex: "F97316")
    static let vitamins = Color(hex: "22C55E")
    static let carbs    = Color(hex: "FACC15")

    // Text
    static let textPrimary   = Color(hex: "78350F")
    static let textSecondary = Color(hex: "92400E")
    static let textMuted     = Color(hex: "A16207")

    // Effects
    static let yellowGlow = Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.3)
    static let greenGlow  = Color(red: 34/255,  green: 197/255, blue: 94/255).opacity(0.25)
    static let softShadow = Color.black.opacity(0.08)

    // Gradients
    static let bgGradient = LinearGradient(
        colors: [bgPrimary, bgSoft],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let grainGradient = LinearGradient(
        colors: [grain, grainActive],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let healthGradient = LinearGradient(
        colors: [healthSoft, healthActive],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let earthGradient = LinearGradient(
        colors: [earthSoft, earthDark],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // MARK: - Aliases used by extended views
    static let grainHighlight = grainGlow
    static let healthMain     = health
    static let earthMain      = earth
    static let cardBg         = cardWhite
    static let textInactive   = textMuted
    static let warningBad     = statusBad
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.cardWhite)
                    .shadow(color: AppTheme.softShadow, radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.bgSoft, lineWidth: 1)
            )
    }

    func ingredientCardStyle() -> some View {
        self
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.cardWarm)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.divider, lineWidth: 1.2)
            )
    }
}
