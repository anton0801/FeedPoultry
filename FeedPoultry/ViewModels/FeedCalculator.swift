import Foundation

struct CalculatorResult {
    var parts: [RecipePart]
    var breakdown: NutrientBreakdown
    var balanceScore: Int          // 0-100
    var warnings: [String]
    var suggestions: [String]
}

enum FeedCalculator {

    /// Compute total daily ration in grams for a flock
    static func dailyRationGrams(birdType: BirdType, count: Int, ageWeeks: Int, goal: FeedGoal) -> Double {
        let base = birdType.dailyFeedGrams * Double(max(count, 1))
        let ageFactor: Double
        switch ageWeeks {
        case ..<4: ageFactor = 0.5
        case 4..<10: ageFactor = 0.8
        case 10..<20: ageFactor = 1.0
        default: ageFactor = 1.05
        }
        let goalFactor: Double
        switch goal {
        case .growth: goalFactor = 1.10
        case .eggProduction: goalFactor = 1.05
        case .maintenance: goalFactor = 0.95
        }
        return base * ageFactor * goalFactor
    }

    /// Greedy mix builder: fills a target ration using available ingredients
    /// while trying to hit target protein, fat and vitamin percentages.
    static func buildMix(birdType: BirdType,
                         ageWeeks: Int,
                         birdWeightGrams: Double,
                         goal: FeedGoal,
                         standard: NutritionStandard,
                         ingredients: [Ingredient],
                         totalGrams: Double) -> CalculatorResult {

        let avail = ingredients.filter { $0.grams > 0 }
        guard totalGrams > 0, !avail.isEmpty else {
            return CalculatorResult(parts: [], breakdown: .zero, balanceScore: 0,
                                    warnings: ["Add ingredients with stock to build a mix."], suggestions: [])
        }

        let targetProtein  = goal.targetProteinPct * standard.proteinMultiplier
        let targetFat      = goal.targetFatPct
        let targetVitamins = goal.targetVitaminsPct

        // Score each ingredient by how well it contributes to the target ratios
        let weights: [(Ingredient, Double)] = avail.map { ing in
            let proteinScore  = max(0, 100 - abs(targetProtein - ing.proteinPct))
            let fatScore      = max(0, 100 - abs(targetFat - ing.fatPct) * 4)
            let vitScore      = max(0, 100 - abs(targetVitamins - ing.vitaminsPct) * 4)
            let costPenalty   = max(0, 30 - ing.pricePerKg * 10) // cheaper = better
            let score = proteinScore * 0.5 + fatScore * 0.2 + vitScore * 0.2 + costPenalty * 0.1
            return (ing, score)
        }

        let totalWeight = weights.reduce(0) { $0 + $1.1 }
        guard totalWeight > 0 else {
            return CalculatorResult(parts: [], breakdown: .zero, balanceScore: 0,
                                    warnings: ["Cannot balance with current ingredients."], suggestions: [])
        }

        // Allocate proportional to score, capped by available stock
        var allocations: [(Ingredient, Double)] = weights.map { ing, score in
            let proposed = totalGrams * (score / totalWeight)
            let actual = min(proposed, ing.grams)
            return (ing, actual)
        }

        // Re-normalize to hit target total exactly
        let allocated = allocations.reduce(0) { $0 + $1.1 }
        if allocated > 0, allocated != totalGrams {
            let scale = totalGrams / allocated
            allocations = allocations.map { ing, g in
                let scaled = min(g * scale, ing.grams)
                return (ing, scaled)
            }
        }

        // Build recipe parts (only > 1g)
        let parts = allocations
            .filter { $0.1 > 1 }
            .map { RecipePart(ingredientId: $0.0.id, grams: $0.1) }

        let breakdown = computeBreakdown(parts: parts, ingredients: ingredients)

        // Warnings & suggestions
        var warnings: [String] = []
        var suggestions: [String] = []

        if breakdown.proteinPct < targetProtein - 2 {
            warnings.append("Low protein vs target (\(Int(targetProtein))%). Consider adding soybean or fish meal.")
            suggestions.append("Add high-protein ingredients (40%+ protein).")
        } else if breakdown.proteinPct > targetProtein + 4 {
            warnings.append("Protein above target — risk of overspending.")
        }

        if breakdown.fatPct < 2 {
            suggestions.append("Add a small amount of oil for energy.")
        }
        if breakdown.vitaminsPct < 3 {
            warnings.append("Vitamin level is low — risk of deficiencies.")
            suggestions.append("Include vitamin/mineral premix (e.g. 1–2%).")
        }

        let proteinDelta  = abs(breakdown.proteinPct - targetProtein)
        let fatDelta      = abs(breakdown.fatPct - targetFat)
        let vitaminsDelta = abs(breakdown.vitaminsPct - targetVitamins)
        let totalDelta    = proteinDelta + fatDelta + vitaminsDelta
        let balance = max(0, min(100, Int(100 - totalDelta * 2)))

        return CalculatorResult(parts: parts,
                                breakdown: breakdown,
                                balanceScore: balance,
                                warnings: warnings,
                                suggestions: suggestions)
    }

    static func computeBreakdown(parts: [RecipePart], ingredients: [Ingredient]) -> NutrientBreakdown {
        var totalGrams = 0.0
        var protein = 0.0, fat = 0.0, vit = 0.0, carbs = 0.0
        var cost = 0.0
        for p in parts {
            guard let ing = ingredients.first(where: { $0.id == p.ingredientId }) else { continue }
            totalGrams += p.grams
            protein += ing.proteinPct * p.grams
            fat     += ing.fatPct     * p.grams
            vit     += ing.vitaminsPct * p.grams
            carbs   += ing.carbsPct   * p.grams
            cost    += (p.grams / 1000.0) * ing.pricePerKg
        }
        guard totalGrams > 0 else { return .zero }
        return NutrientBreakdown(
            proteinPct:  protein / totalGrams,
            fatPct:      fat / totalGrams,
            vitaminsPct: vit / totalGrams,
            carbsPct:    carbs / totalGrams,
            totalGrams:  totalGrams,
            totalCost:   cost
        )
    }
}
