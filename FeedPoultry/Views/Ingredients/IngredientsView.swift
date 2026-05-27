import SwiftUI

struct IngredientsView: View {
    @EnvironmentObject var data: DataStore
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(spacing: 12) {
                    HStack {
                        SectionHeader(title: "Ingredients", subtitle: "\(data.ingredients.count) items in your library")
                        Button {
                            showAdd = true
                        } label: {
                            ZStack {
                                Circle().fill(AppTheme.grain).frame(width: 40, height: 40)
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .heavy))
                                    .foregroundColor(AppTheme.earthDark)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)

                    if data.ingredients.isEmpty {
                        EmptyState(icon: "leaf.fill",
                                   title: "No ingredients yet",
                                   message: "Add corn, wheat, soybean meal and more to start mixing feeds.")
                    } else {
                        ForEach(data.ingredients) { ing in
                            NavigationLink {
                                IngredientEditView(ingredient: ing)
                            } label: {
                                IngredientRow(ing: ing)
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
        .navigationTitle("Ingredients")
        .sheet(isPresented: $showAdd) {
            IngredientEditView(ingredient: nil)
        }
    }
}

struct IngredientRow: View {
    let ing: Ingredient
    @EnvironmentObject var appState: AppState
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(AppTheme.grainGlow.opacity(0.4)).frame(width: 44, height: 44)
                Image(systemName: "leaf.fill").foregroundColor(AppTheme.grainActive)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(ing.name).font(.system(size: 15, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                HStack(spacing: 8) {
                    Tag(text: "P \(Int(ing.proteinPct))%", color: AppTheme.protein)
                    Tag(text: "F \(Int(ing.fatPct))%", color: AppTheme.fat)
                    Tag(text: "V \(Int(ing.vitaminsPct))%", color: AppTheme.vitamins)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(appState.formattedWeight(ing.grams))
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.earthDark)
                Text(appState.formattedMoney(ing.pricePerKg) + "/kg")
                    .font(.system(size: 11)).foregroundColor(AppTheme.textMuted)
            }
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundColor(AppTheme.textMuted)
        }
        .ingredientCardStyle()
    }
}

private struct Tag: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.15)))
    }
}

struct IngredientEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var data: DataStore
    let ingredient: Ingredient?

    @State private var name: String = ""
    @State private var grams: String = ""
    @State private var pricePerKg: String = ""
    @State private var protein: Double = 10
    @State private var fat: Double = 4
    @State private var vitamins: Double = 2
    @State private var carbs: Double = 84
    @State private var note: String = ""

    private var isEdit: Bool { ingredient != nil }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(spacing: 12) {
                    SectionHeader(title: isEdit ? "Edit Ingredient" : "Add Ingredient",
                                  subtitle: isEdit ? "Update values and save" : "Add to your library")
                        .padding(.horizontal, 18).padding(.top, 6)

                    VStack(spacing: 10) {
                        AppTextField(placeholder: "Name", text: $name, icon: "textformat")
                        HStack(spacing: 10) {
                            AppTextField(placeholder: "Amount (g)", text: $grams, icon: "scalemass.fill", keyboard: .decimalPad)
                            AppTextField(placeholder: "Price/kg", text: $pricePerKg, icon: "dollarsign.circle.fill", keyboard: .decimalPad)
                        }
                    }
                    .cardStyle()
                    .padding(.horizontal, 18)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Nutrition (%)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.textMuted)
                        nutrientSlider(label: "Protein", value: $protein, color: AppTheme.protein)
                        nutrientSlider(label: "Fat",     value: $fat,     color: AppTheme.fat)
                        nutrientSlider(label: "Vitamins",value: $vitamins,color: AppTheme.vitamins)
                        nutrientSlider(label: "Carbs",   value: $carbs,   color: AppTheme.carbs)
                        Text("Sum: \(Int(protein + fat + vitamins + carbs))%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .cardStyle()
                    .padding(.horizontal, 18)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes").font(.system(size: 13, weight: .bold)).foregroundColor(AppTheme.textMuted)
                        AppTextField(placeholder: "Optional notes", text: $note, icon: "note.text")
                    }
                    .padding(.horizontal, 18)

                    VStack(spacing: 8) {
                        PrimaryButton(title: isEdit ? "Save Changes" : "Add Ingredient",
                                      icon: "checkmark") {
                            save()
                        }
                        if isEdit {
                            SecondaryButton(title: "Delete Ingredient", icon: "trash.fill") {
                                if let ing = ingredient,
                                   let idx = data.ingredients.firstIndex(where: { $0.id == ing.id }) {
                                    data.deleteIngredient(at: IndexSet(integer: idx))
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { populate() }
    }

    private func populate() {
        if let ing = ingredient {
            name = ing.name
            grams = String(format: "%.0f", ing.grams)
            pricePerKg = String(format: "%.2f", ing.pricePerKg)
            protein = ing.proteinPct
            fat = ing.fatPct
            vitamins = ing.vitaminsPct
            carbs = ing.carbsPct
            note = ing.note
        }
    }

    private func nutrientSlider(label: String, value: Binding<Double>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(Int(value.wrappedValue))%")
                    .font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundColor(color)
            }
            Slider(value: value, in: 0...100, step: 1)
                .accentColor(color)
        }
    }

    private func save() {
        let g = Double(grams.replacingOccurrences(of: ",", with: ".")) ?? 0
        let p = Double(pricePerKg.replacingOccurrences(of: ",", with: ".")) ?? 0
        let displayName = name.trimmingCharacters(in: .whitespaces).isEmpty ? "New Ingredient" : name

        if var existing = ingredient {
            existing.name = displayName
            existing.grams = g
            existing.pricePerKg = p
            existing.proteinPct = protein
            existing.fatPct = fat
            existing.vitaminsPct = vitamins
            existing.carbsPct = carbs
            existing.note = note
            data.updateIngredient(existing)
        } else {
            let ing = Ingredient(name: displayName, grams: g, pricePerKg: p,
                                 proteinPct: protein, fatPct: fat,
                                 vitaminsPct: vitamins, carbsPct: carbs, note: note)
            data.addIngredient(ing)
        }
        dismiss()
    }
}
