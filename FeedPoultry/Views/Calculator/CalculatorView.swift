import SwiftUI

final class CalculatorViewModel: ObservableObject {
    @Published var birdType: BirdType = .chicken
    @Published var goal: FeedGoal = .growth
    @Published var ageWeeks: Double = 8
    @Published var birdWeightGrams: Double = 1500
    @Published var birdCount: Double = 10
    @Published var totalGramsOverride: Double? = nil
    @Published var result: CalculatorResult? = nil

    func compute(ingredients: [Ingredient], standard: NutritionStandard) {
        let dailyTotal = totalGramsOverride ?? FeedCalculator.dailyRationGrams(
            birdType: birdType,
            count: Int(birdCount),
            ageWeeks: Int(ageWeeks),
            goal: goal
        )
        let r = FeedCalculator.buildMix(
            birdType: birdType,
            ageWeeks: Int(ageWeeks),
            birdWeightGrams: birdWeightGrams,
            goal: goal,
            standard: standard,
            ingredients: ingredients,
            totalGrams: dailyTotal
        )
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            result = r
        }
    }
}

struct CalculatorView: View {
    @EnvironmentObject var data: DataStore
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = CalculatorViewModel()

    var initialBird: BirdType? = nil

    @State private var showResult = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(spacing: 14) {
                    SectionHeader(title: "Feed Calculator",
                                  subtitle: "Mix the perfect ration in seconds")
                        .padding(.horizontal, 18)
                        .padding(.top, 6)

                    // Bird type
                    SelectorCard(title: "Bird Type") {
                        HStack(spacing: 8) {
                            ForEach(BirdType.allCases) { bt in
                                PillButton(title: bt.title,
                                           systemImage: nil,
                                           isSelected: vm.birdType == bt) {
                                    vm.birdType = bt
                                }
                            }
                        }
                    }

                    // Goal
                    SelectorCard(title: "Goal") {
                        VStack(spacing: 8) {
                            ForEach(FeedGoal.allCases) { goal in
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        vm.goal = goal
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: goal.icon)
                                            .foregroundColor(vm.goal == goal ? AppTheme.earthDark : AppTheme.earth)
                                        Text(goal.title).fontWeight(.semibold)
                                            .foregroundColor(vm.goal == goal ? AppTheme.earthDark : AppTheme.textSecondary)
                                        Spacer()
                                        Text("\(Int(goal.targetProteinPct))% protein")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(AppTheme.protein)
                                    }
                                    .padding(.horizontal, 14).padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(vm.goal == goal ? AppTheme.grain : AppTheme.cardWarm)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(vm.goal == goal ? AppTheme.grainActive : AppTheme.divider, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Age
                    SliderCard(title: "Age",
                               value: $vm.ageWeeks,
                               range: 1...52, step: 1,
                               formatted: "\(Int(vm.ageWeeks)) weeks",
                               icon: "calendar")

                    // Weight
                    SliderCard(title: "Weight per bird",
                               value: $vm.birdWeightGrams,
                               range: 50...5000, step: 50,
                               formatted: appState.formattedWeight(vm.birdWeightGrams),
                               icon: "scalemass.fill")

                    // Count
                    SliderCard(title: "Number of birds",
                               value: $vm.birdCount,
                               range: 1...500, step: 1,
                               formatted: "\(Int(vm.birdCount)) birds",
                               icon: "person.3.fill")

                    // Compute button
                    PrimaryButton(title: "Calculate Mix", icon: "sparkles") {
                        vm.compute(ingredients: data.ingredients,
                                   standard: appState.nutritionStandard)
                        withAnimation { showResult = true }
                    }
                    .padding(.horizontal, 18)

                    if let r = vm.result {
                        ResultPanel(viewModel: vm, result: r)
                            .padding(.horizontal, 18)
                            .padding(.bottom, 100)
                    } else {
                        Spacer(minLength: 80)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let initialBird {
                vm.birdType = initialBird
            }
        }
    }
}

private struct SelectorCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.textMuted)
            content()
        }
        .cardStyle()
        .padding(.horizontal, 18)
    }
}

private struct SliderCard: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let formatted: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundColor(AppTheme.earth)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                Spacer()
                Text(formatted)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
            Slider(value: $value, in: range, step: step)
                .accentColor(AppTheme.grainActive)
        }
        .cardStyle()
        .padding(.horizontal, 18)
    }
}

private struct ResultPanel: View {
    @ObservedObject var viewModel: CalculatorViewModel
    let result: CalculatorResult
    @EnvironmentObject var data: DataStore
    @EnvironmentObject var appState: AppState
    @State private var savedConfirmation: String? = nil
    @State private var showSaveSheet = false
    @State private var showAdjust = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recipe Result")
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Total \(appState.formattedWeight(result.breakdown.totalGrams)) · \(appState.formattedMoney(result.breakdown.totalCost))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textMuted)
                }
                Spacer()
                BalanceGauge(score: result.balanceScore)
            }

            // Composition list
            VStack(alignment: .leading, spacing: 8) {
                Text("Composition")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                ForEach(result.parts) { part in
                    if let ing = data.ingredient(by: part.ingredientId) {
                        HStack {
                            ZStack {
                                Circle().fill(AppTheme.grain.opacity(0.2)).frame(width: 30, height: 30)
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(AppTheme.grainActive)
                                    .font(.system(size: 13, weight: .bold))
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(ing.name).font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text(String(format: "%.0f%%", (part.grams / max(result.breakdown.totalGrams, 1)) * 100))
                                    .font(.system(size: 11)).foregroundColor(AppTheme.textMuted)
                            }
                            Spacer()
                            Text(appState.formattedWeight(part.grams))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.earthDark)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Nutrient breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("Nutrients")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                NutrientBar(label: "Protein",
                            percent: result.breakdown.proteinPct,
                            target: viewModel.goal.targetProteinPct * appState.nutritionStandard.proteinMultiplier,
                            color: AppTheme.protein)
                NutrientBar(label: "Fat",
                            percent: result.breakdown.fatPct,
                            target: viewModel.goal.targetFatPct,
                            color: AppTheme.fat)
                NutrientBar(label: "Vitamins",
                            percent: result.breakdown.vitaminsPct,
                            target: viewModel.goal.targetVitaminsPct,
                            color: AppTheme.vitamins)
                NutrientBar(label: "Carbs",
                            percent: result.breakdown.carbsPct,
                            target: viewModel.goal.targetCarbsPct,
                            color: AppTheme.carbs)
            }

            if !result.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(result.warnings, id: \.self) { w in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppTheme.statusWarning)
                            Text(w).font(.system(size: 12)).foregroundColor(AppTheme.textPrimary)
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.statusWarning.opacity(0.12)))
            }

            if !result.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(result.suggestions, id: \.self) { s in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill").foregroundColor(AppTheme.health)
                            Text(s).font(.system(size: 12)).foregroundColor(AppTheme.textPrimary)
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.health.opacity(0.12)))
            }

            // Action buttons
            VStack(spacing: 8) {
                PrimaryButton(title: "Save Recipe", icon: "bookmark.fill") {
                    showSaveSheet = true
                }
                HStack(spacing: 8) {
                    SecondaryButton(title: "Adjust Mix", icon: "slider.horizontal.below.rectangle") {
                        showAdjust = true
                    }
                    SecondaryButton(title: "Use Stock", icon: "shippingbox.fill") {
                        useStock()
                    }
                }
            }

            if let savedConfirmation {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.health)
                    Text(savedConfirmation).font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.health)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.health.opacity(0.12)))
            }
        }
        .cardStyle(padding: 16)
        .sheet(isPresented: $showSaveSheet) {
            SaveRecipeSheet(viewModel: viewModel, result: result) { name in
                let recipe = Recipe(
                    name: name,
                    birdType: viewModel.birdType,
                    goal: viewModel.goal,
                    ageWeeks: Int(viewModel.ageWeeks),
                    birdWeightGrams: viewModel.birdWeightGrams,
                    parts: result.parts
                )
                data.saveRecipe(recipe)
                withAnimation { savedConfirmation = "Saved as \(name)" }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { savedConfirmation = nil }
                }
            }
        }
        .sheet(isPresented: $showAdjust) {
            AdjustMixView(viewModel: viewModel, currentResult: result)
        }
    }

    private func useStock() {
        for part in result.parts {
            data.adjustStock(ingredientId: part.ingredientId, deltaGrams: -part.grams, kind: .used)
        }
        let cost = result.breakdown.totalCost
        if cost > 0 {
            data.addCost(CostRecord(title: "Mixed feed", amount: cost, category: "Feed"))
        }
        withAnimation { savedConfirmation = "Stock updated" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { savedConfirmation = nil }
        }
    }
}

private struct SaveRecipeSheet: View {
    @ObservedObject var viewModel: CalculatorViewModel
    let result: CalculatorResult
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Save Recipe")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24)).foregroundColor(AppTheme.earth)
                    }
                }
                AppTextField(placeholder: "Recipe name", text: $name, icon: "textformat")
                Text("Bird: \(viewModel.birdType.title) · \(viewModel.goal.title)")
                    .font(.system(size: 13)).foregroundColor(AppTheme.textMuted)
                Spacer()
                PrimaryButton(title: "Save", icon: "checkmark") {
                    let final = name.isEmpty ? "\(viewModel.birdType.title) \(viewModel.goal.title) Mix" : name
                    onSave(final)
                    dismiss()
                }
            }
            .padding(20)
            .padding(.top, 12)
        }
    }
}
