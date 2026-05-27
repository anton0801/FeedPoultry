import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var appState: AppState
    @State private var range: RangeFilter = .month

    enum RangeFilter: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case all = "All"
        var id: String { rawValue }

        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .all: return nil
            }
        }
    }

    var filteredCosts: [CostRecord] {
        guard let days = range.days else { return store.costs }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return store.costs.filter { $0.date >= cutoff }
    }

    var totalSpent: Double {
        filteredCosts.reduce(0) { $0 + $1.amount }
    }

    var avgPerDay: Double {
        let days = max(1, range.days ?? 30)
        return totalSpent / Double(days)
    }

    var dailyBuckets: [(label: String, value: Double)] {
        let days = range.days ?? 30
        let cal = Calendar.current
        var result: [(String, Double)] = []
        for i in (0..<min(days, 14)).reversed() {
            let day = cal.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let total = store.costs.filter {
                cal.isDate($0.date, inSameDayAs: day)
            }.reduce(0) { $0 + $1.amount }
            let label = i == 0 ? "Today" : "\(cal.component(.day, from: day))"
            result.append((label, total))
        }
        return result
    }

    var nutrientAverages: NutrientBreakdown {
        guard !store.recipes.isEmpty else {
            return NutrientBreakdown.zero
        }
        let totals = store.recipes.reduce(NutrientBreakdown.zero) { acc, recipe in
            let b = FeedCalculator.computeBreakdown(parts: recipe.parts, ingredients: store.ingredients)
            return NutrientBreakdown(
                proteinPct: acc.proteinPct + b.proteinPct,
                fatPct: acc.fatPct + b.fatPct,
                vitaminsPct: acc.vitaminsPct + b.vitaminsPct,
                carbsPct: acc.carbsPct + b.carbsPct,
                totalGrams: 0,
                totalCost: 0
            )
        }
        let count = Double(store.recipes.count)
        return NutrientBreakdown(
            proteinPct: totals.proteinPct / count,
            fatPct: totals.fatPct / count,
            vitaminsPct: totals.vitaminsPct / count,
            carbsPct: totals.carbsPct / count,
            totalGrams: 0,
            totalCost: 0
        )
    }

    var maxBucket: Double {
        max(1, dailyBuckets.map(\.value).max() ?? 1)
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Picker("Range", selection: $range) {
                        ForEach(RangeFilter.allCases) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 12) {
                        StatTile(
                            title: "Spent",
                            value: appState.formattedMoney(totalSpent),
                            icon: "dollarsign.circle.fill",
                            tint: AppTheme.earthMain
                        )
                        StatTile(
                            title: "Avg / Day",
                            value: appState.formattedMoney(avgPerDay),
                            icon: "chart.line.uptrend.xyaxis",
                            tint: AppTheme.healthMain
                        )
                    }

                    SectionHeader(title: "Spending Trend", subtitle: "Last \(dailyBuckets.count) days")
                    chartCard

                    SectionHeader(title: "Average Nutrients", subtitle: "Across saved recipes")
                    nutrientCard

                    SectionHeader(title: "Top Recipes", subtitle: "By balance score")
                    topRecipesCard
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Reports")
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(dailyBuckets.enumerated()), id: \.offset) { idx, item in
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottom) {
                            Capsule()
                                .fill(AppTheme.bgSoft)
                                .frame(width: 16, height: 100)
                            Capsule()
                                .fill(AppTheme.grainGradient)
                                .frame(
                                    width: 16,
                                    height: max(4, CGFloat(item.value / maxBucket) * 100)
                                )
                        }
                        Text(item.label)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(AppTheme.textInactive)
                    }
                }
            }
            if filteredCosts.isEmpty {
                Text("No spending data yet.")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var nutrientCard: some View {
        VStack(spacing: 14) {
            NutrientBar(label: "Protein", percent: nutrientAverages.proteinPct, target: 18, color: AppTheme.protein)
            NutrientBar(label: "Fat", percent: nutrientAverages.fatPct, target: 5, color: AppTheme.fat)
            NutrientBar(label: "Vitamins", percent: nutrientAverages.vitaminsPct, target: 2, color: AppTheme.vitamins)
            NutrientBar(label: "Carbs", percent: nutrientAverages.carbsPct, target: 60, color: AppTheme.carbs)
        }
        .cardStyle()
    }

    private var topRecipesCard: some View {
        let scored: [(recipe: Recipe, score: Double)] = store.recipes.map { recipe in
            let breakdown = FeedCalculator.computeBreakdown(parts: recipe.parts, ingredients: store.ingredients)
            let g = recipe.goal
            let pDelta = abs(breakdown.proteinPct - g.targetProteinPct) / max(1, g.targetProteinPct)
            let fDelta = abs(breakdown.fatPct - g.targetFatPct) / max(1, g.targetFatPct)
            let vDelta = abs(breakdown.vitaminsPct - g.targetVitaminsPct) / max(1, g.targetVitaminsPct)
            let cDelta = abs(breakdown.carbsPct - g.targetCarbsPct) / max(1, g.targetCarbsPct)
            let avgDelta = (pDelta + fDelta + vDelta + cDelta) / 4
            let score = max(0, min(100, (1 - avgDelta) * 100))
            return (recipe, score)
        }
        let top = scored.sorted { $0.score > $1.score }.prefix(4)

        return VStack(spacing: 0) {
            if top.isEmpty {
                EmptyState(icon: "chart.bar.doc.horizontal", title: "No recipes saved yet")
                    .padding(.vertical, 16)
            } else {
                ForEach(Array(top.enumerated()), id: \.element.recipe.id) { idx, item in
                    HStack(spacing: 12) {
                        Text("\(idx + 1)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.earthMain)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(AppTheme.grainHighlight))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.recipe.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("\(item.recipe.birdType.title) • \(item.recipe.goal.title)")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        Spacer()

                        Text("\(Int(item.score))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.healthActive)
                    }
                    .padding(.vertical, 10)
                    if idx < top.count - 1 {
                        Divider().background(AppTheme.divider)
                    }
                }
            }
        }
        .cardStyle()
    }
}
