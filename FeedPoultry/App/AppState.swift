import SwiftUI
import Combine

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    var displayName: String { title }
}

enum WeightUnit: String, CaseIterable, Identifiable {
    case grams, kilograms, pounds
    var id: String { rawValue }
    var title: String {
        switch self {
        case .grams: return "Grams (g)"
        case .kilograms: return "Kilograms (kg)"
        case .pounds: return "Pounds (lb)"
        }
    }
    var short: String {
        switch self {
        case .grams: return "g"
        case .kilograms: return "kg"
        case .pounds: return "lb"
        }
    }
    var displayName: String { short.uppercased() }
}

enum CurrencyCode: String, CaseIterable, Identifiable {
    case usd, eur, gbp, rub
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .rub: return "₽"
        }
    }
    var title: String {
        switch self {
        case .usd: return "USD ($)"
        case .eur: return "EUR (€)"
        case .gbp: return "GBP (£)"
        case .rub: return "RUB (₽)"
        }
    }
}

enum NutritionStandard: String, CaseIterable, Identifiable {
    case standard, performance, organic
    var id: String { rawValue }
    var title: String {
        switch self {
        case .standard: return "Standard"
        case .performance: return "Performance"
        case .organic: return "Organic"
        }
    }
    var detail: String {
        switch self {
        case .standard: return "Balanced everyday nutrition"
        case .performance: return "Higher protein, faster growth"
        case .organic: return "Natural ingredients only"
        }
    }
    /// Multiplier applied to recommended protein in calculations
    var proteinMultiplier: Double {
        switch self {
        case .standard: return 1.00
        case .performance: return 1.10
        case .organic: return 0.95
        }
    }
    var displayName: String { title }
    var description: String { detail }
}

final class AppState: ObservableObject {
    @AppStorage("appearanceMode") private var storedAppearance: String = AppearanceMode.system.rawValue
    @AppStorage("weightUnit")     private var storedWeightUnit: String = WeightUnit.grams.rawValue
    @AppStorage("currency")       private var storedCurrency: String = CurrencyCode.usd.rawValue
    @AppStorage("nutritionStandard") private var storedStandard: String = NutritionStandard.standard.rawValue
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("dailyReminderHour") var dailyReminderHour: Int = 8
    @AppStorage("userName") var userName: String = "Farmer"
    @AppStorage("farmName") var farmName: String = "My Farm"
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    @Published var appearance: AppearanceMode = .system {
        didSet { storedAppearance = appearance.rawValue; objectWillChange.send() }
    }
    @Published var weightUnit: WeightUnit = .grams {
        didSet { storedWeightUnit = weightUnit.rawValue }
    }
    @Published var currency: CurrencyCode = .usd {
        didSet { storedCurrency = currency.rawValue }
    }
    @Published var nutritionStandard: NutritionStandard = .standard {
        didSet { storedStandard = nutritionStandard.rawValue }
    }

    init() {
        appearance = AppearanceMode(rawValue: storedAppearance) ?? .system
        weightUnit = WeightUnit(rawValue: storedWeightUnit) ?? .grams
        currency = CurrencyCode(rawValue: storedCurrency) ?? .usd
        nutritionStandard = NutritionStandard(rawValue: storedStandard) ?? .standard
    }

    var colorScheme: ColorScheme? {
        switch appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func formattedWeight(_ grams: Double) -> String {
        switch weightUnit {
        case .grams: return String(format: "%.0f g", grams)
        case .kilograms: return String(format: "%.2f kg", grams / 1000.0)
        case .pounds: return String(format: "%.2f lb", grams / 453.592)
        }
    }

    func formattedMoney(_ value: Double) -> String {
        String(format: "%@%.2f", currency.symbol, value)
    }
}
