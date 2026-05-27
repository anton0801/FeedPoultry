import Foundation
import SwiftUI

// MARK: - Bird

enum BirdType: String, Codable, CaseIterable, Identifiable {
    case chicken, duck, quail
    var id: String { rawValue }
    var title: String {
        switch self {
        case .chicken: return "Chicken"
        case .duck: return "Duck"
        case .quail: return "Quail"
        }
    }
    var symbol: String {
        switch self {
        case .chicken: return "bird.fill"
        case .duck:    return "tortoise.fill" // placeholder, custom drawn elsewhere
        case .quail:   return "leaf.fill"
        }
    }
    var emoji: String {
        switch self {
        case .chicken: return "🐔"
        case .duck:    return "🦆"
        case .quail:   return "🐦"
        }
    }
    /// Average daily feed in grams per bird (rough working figure)
    var dailyFeedGrams: Double {
        switch self {
        case .chicken: return 120
        case .duck:    return 180
        case .quail:   return 25
        }
    }
}

enum FeedGoal: String, Codable, CaseIterable, Identifiable {
    case growth, eggProduction, maintenance
    var id: String { rawValue }
    var title: String {
        switch self {
        case .growth: return "Growth"
        case .eggProduction: return "Egg Production"
        case .maintenance: return "Maintenance"
        }
    }
    var icon: String {
        switch self {
        case .growth: return "arrow.up.right.circle.fill"
        case .eggProduction: return "circle.hexagongrid.fill"
        case .maintenance: return "leaf.circle.fill"
        }
    }
    /// Recommended protein % for goal
    var targetProteinPct: Double {
        switch self {
        case .growth: return 22
        case .eggProduction: return 18
        case .maintenance: return 15
        }
    }
    var targetFatPct: Double { 6 }
    var targetVitaminsPct: Double { 4 }
    var targetCarbsPct: Double {
        100 - (targetProteinPct + targetFatPct + targetVitaminsPct)
    }
}

// MARK: - Ingredient

struct Ingredient: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var grams: Double          // available stock
    var pricePerKg: Double     // user currency / kg
    var proteinPct: Double
    var fatPct: Double
    var vitaminsPct: Double
    var carbsPct: Double
    var note: String = ""

    var iconColor: Color { AppTheme.grain }

    static func defaults() -> [Ingredient] {
        [
            Ingredient(name: "Corn",        grams: 5000, pricePerKg: 0.45, proteinPct: 9,  fatPct: 4, vitaminsPct: 2, carbsPct: 85),
            Ingredient(name: "Wheat",       grams: 4000, pricePerKg: 0.40, proteinPct: 12, fatPct: 2, vitaminsPct: 3, carbsPct: 83),
            Ingredient(name: "Soybean Meal",grams: 2500, pricePerKg: 0.80, proteinPct: 44, fatPct: 2, vitaminsPct: 6, carbsPct: 48),
            Ingredient(name: "Fish Meal",   grams: 1000, pricePerKg: 1.50, proteinPct: 60, fatPct: 9, vitaminsPct: 8, carbsPct: 23),
            Ingredient(name: "Sunflower Oil",grams: 800, pricePerKg: 1.20, proteinPct: 0,  fatPct: 99,vitaminsPct: 1, carbsPct: 0),
            Ingredient(name: "Limestone",   grams: 1500, pricePerKg: 0.20, proteinPct: 0,  fatPct: 0, vitaminsPct: 95,carbsPct: 5),
            Ingredient(name: "Vitamin Mix", grams: 500,  pricePerKg: 3.00, proteinPct: 0,  fatPct: 0, vitaminsPct: 100,carbsPct: 0),
        ]
    }
}

// MARK: - Recipe

struct RecipePart: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var ingredientId: UUID
    var grams: Double
}

struct Recipe: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var birdType: BirdType
    var goal: FeedGoal
    var ageWeeks: Int
    var birdWeightGrams: Double
    var parts: [RecipePart]
    var createdAt: Date = Date()
    var notes: String = ""
}

// MARK: - Stock movement

enum StockChangeKind: String, Codable, CaseIterable {
    case added, used, adjusted
    var title: String {
        switch self {
        case .added: return "Added"
        case .used: return "Used"
        case .adjusted: return "Adjusted"
        }
    }
    var color: Color {
        switch self {
        case .added: return AppTheme.health
        case .used: return AppTheme.statusBad
        case .adjusted: return AppTheme.earthSoft
        }
    }
}

struct StockEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var ingredientId: UUID
    var ingredientName: String
    var grams: Double
    var kind: StockChangeKind
    var date: Date = Date()
}

// MARK: - Cost record

struct CostRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var category: String
    var date: Date = Date()
}

// MARK: - Tasks

enum TaskRecurrence: String, Codable, CaseIterable, Identifiable {
    case once, daily, weekly
    var id: String { rawValue }
    var title: String {
        switch self {
        case .once: return "One time"
        case .daily: return "Every day"
        case .weekly: return "Every week"
        }
    }
    var displayName: String {
        switch self {
        case .once: return "Once"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
}

struct FeedingTask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var scheduledAt: Date
    var recurrence: TaskRecurrence
    var notify: Bool = true
    var isDone: Bool = false
    var notes: String = ""
}

// MARK: - Activity history

struct ActivityEvent: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var detail: String
    var icon: String
    var date: Date = Date()
}

// MARK: - Computed nutrient breakdown

struct NutrientBreakdown {
    var proteinPct: Double
    var fatPct: Double
    var vitaminsPct: Double
    var carbsPct: Double
    var totalGrams: Double
    var totalCost: Double

    static let zero = NutrientBreakdown(proteinPct: 0, fatPct: 0, vitaminsPct: 0, carbsPct: 0, totalGrams: 0, totalCost: 0)
}
