import SwiftUI

struct AdjustMixView: View {
    @ObservedObject var viewModel: CalculatorViewModel
    let currentResult: CalculatorResult
    @EnvironmentObject var data: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var amounts: [UUID: Double] = [:]

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Adjust Mix")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26)).foregroundColor(AppTheme.earth)
                    }
                }
                Text("Tweak amounts. Total: \(appState.formattedWeight(amounts.values.reduce(0, +)))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(currentResult.parts) { part in
                            if let ing = data.ingredient(by: part.ingredientId) {
                                let current = amounts[part.id] ?? part.grams
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(ing.name).font(.system(size: 14, weight: .bold))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Spacer()
                                        Text(appState.formattedWeight(current))
                                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                                            .foregroundColor(AppTheme.earthDark)
                                    }
                                    Slider(value: Binding(
                                        get: { amounts[part.id] ?? part.grams },
                                        set: { amounts[part.id] = $0 }
                                    ), in: 0...max(ing.grams, part.grams * 2), step: 5)
                                    .accentColor(AppTheme.grainActive)
                                    Text("Stock available: \(appState.formattedWeight(ing.grams))")
                                        .font(.system(size: 11)).foregroundColor(AppTheme.textMuted)
                                }
                                .ingredientCardStyle()
                            }
                        }
                    }
                }

                PrimaryButton(title: "Apply Changes", icon: "checkmark") {
                    let newParts: [RecipePart] = currentResult.parts.map { p in
                        var copy = p
                        copy.grams = amounts[p.id] ?? p.grams
                        return copy
                    }.filter { $0.grams > 0 }

                    let breakdown = FeedCalculator.computeBreakdown(parts: newParts, ingredients: data.ingredients)
                    viewModel.result = CalculatorResult(
                        parts: newParts,
                        breakdown: breakdown,
                        balanceScore: currentResult.balanceScore, // approximation
                        warnings: currentResult.warnings,
                        suggestions: currentResult.suggestions
                    )
                    dismiss()
                }
            }
            .padding(20)
            .padding(.top, 8)
            .onAppear {
                for p in currentResult.parts { amounts[p.id] = p.grams }
            }
        }
    }
}
