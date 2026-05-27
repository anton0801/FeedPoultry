import SwiftUI

struct RecipesView: View {
    @EnvironmentObject var data: DataStore

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(spacing: 12) {
                    SectionHeader(title: "Saved Recipes", subtitle: "\(data.recipes.count) recipes saved")
                        .padding(.horizontal, 18).padding(.top, 6)

                    if data.recipes.isEmpty {
                        EmptyState(icon: "book.fill",
                                   title: "No recipes yet",
                                   message: "Use the calculator to mix and save your first recipe.")
                            .padding(.horizontal, 18)
                    } else {
                        ForEach(data.recipes) { r in
                            NavigationLink {
                                RecipeDetailView(recipe: r)
                            } label: {
                                RecipeCard(recipe: r)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 18)
                        }
                    }
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Recipes")
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    @EnvironmentObject var data: DataStore
    @EnvironmentObject var appState: AppState

    var body: some View {
        let breakdown = FeedCalculator.computeBreakdown(parts: recipe.parts, ingredients: data.ingredients)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(recipe.birdType.emoji).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.name).font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("\(recipe.goal.title) · \(recipe.ageWeeks) wk")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textMuted)
                }
                Spacer()
                Text(appState.formattedWeight(breakdown.totalGrams))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.earthDark)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(AppTheme.bgSoft))
            }
            HStack(spacing: 6) {
                Tag(text: "P \(Int(breakdown.proteinPct))%", color: AppTheme.protein)
                Tag(text: "F \(Int(breakdown.fatPct))%", color: AppTheme.fat)
                Tag(text: "V \(Int(breakdown.vitaminsPct))%", color: AppTheme.vitamins)
                Tag(text: "C \(Int(breakdown.carbsPct))%", color: AppTheme.carbs)
            }
        }
        .cardStyle()
    }
}

private struct Tag: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.15)))
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    @EnvironmentObject var data: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let breakdown = FeedCalculator.computeBreakdown(parts: recipe.parts, ingredients: data.ingredients)
        return ZStack {
            ScreenBackground()
            ScrollView {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(recipe.birdType.emoji).font(.system(size: 36))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(recipe.name).font(.system(size: 22, weight: .heavy, design: .rounded))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text("\(recipe.goal.title) · \(recipe.ageWeeks) weeks · \(appState.formattedWeight(recipe.birdWeightGrams))/bird")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                    .padding(.horizontal, 18)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Composition").font(.system(size: 14, weight: .bold)).foregroundColor(AppTheme.textMuted)
                        ForEach(recipe.parts) { p in
                            if let ing = data.ingredient(by: p.ingredientId) {
                                HStack {
                                    Image(systemName: "leaf.fill").foregroundColor(AppTheme.grainActive)
                                    Text(ing.name).font(.system(size: 14, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    Text(appState.formattedWeight(p.grams))
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(AppTheme.earthDark)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .cardStyle()
                    .padding(.horizontal, 18)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Nutrients").font(.system(size: 14, weight: .bold)).foregroundColor(AppTheme.textMuted)
                        NutrientBar(label: "Protein", percent: breakdown.proteinPct,
                                    target: recipe.goal.targetProteinPct, color: AppTheme.protein)
                        NutrientBar(label: "Fat", percent: breakdown.fatPct,
                                    target: recipe.goal.targetFatPct, color: AppTheme.fat)
                        NutrientBar(label: "Vitamins", percent: breakdown.vitaminsPct,
                                    target: recipe.goal.targetVitaminsPct, color: AppTheme.vitamins)
                        NutrientBar(label: "Carbs", percent: breakdown.carbsPct,
                                    target: recipe.goal.targetCarbsPct, color: AppTheme.carbs)
                    }
                    .cardStyle()
                    .padding(.horizontal, 18)

                    VStack(spacing: 8) {
                        PrimaryButton(title: "Use Recipe (deduct stock)", icon: "shippingbox.fill") {
                            for p in recipe.parts {
                                data.adjustStock(ingredientId: p.ingredientId, deltaGrams: -p.grams, kind: .used)
                            }
                            data.addCost(CostRecord(title: "Used \(recipe.name)",
                                                    amount: breakdown.totalCost,
                                                    category: "Feed"))
                            dismiss()
                        }
                        SecondaryButton(title: "Delete Recipe", icon: "trash.fill") {
                            if let idx = data.recipes.firstIndex(where: { $0.id == recipe.id }) {
                                data.deleteRecipe(at: IndexSet(integer: idx))
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
