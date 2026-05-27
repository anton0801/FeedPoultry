import SwiftUI

struct StockView: View {
    @EnvironmentObject var data: DataStore
    @EnvironmentObject var appState: AppState
    @State private var sheet: ActiveSheet? = nil

    enum ActiveSheet: Identifiable {
        case adjust(Ingredient)
        var id: String {
            switch self {
            case .adjust(let i): return "adjust-\(i.id)"
            }
        }
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(spacing: 12) {
                    SectionHeader(title: "Stock", subtitle: "Track and adjust your feed inventory")
                        .padding(.horizontal, 18).padding(.top, 6)

                    HStack(spacing: 12) {
                        StatTile(title: "Total stock",
                                 value: appState.formattedWeight(data.totalStockGrams),
                                 icon: "shippingbox.fill", tint: AppTheme.grainActive)
                        StatTile(title: "Stock value",
                                 value: appState.formattedMoney(data.totalStockValue),
                                 icon: "dollarsign.circle.fill", tint: AppTheme.health)
                    }
                    .padding(.horizontal, 18)

                    NavigationLink {
                        OptimizationView()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14).fill(AppTheme.health.opacity(0.18)).frame(width: 44, height: 44)
                                Image(systemName: "leaf.arrow.circlepath").foregroundColor(AppTheme.health)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Optimization").font(.system(size: 15, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text("Save up to 20% on feed cost")
                                    .font(.system(size: 12)).foregroundColor(AppTheme.textMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(AppTheme.textMuted)
                        }
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Inventory")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.textMuted)
                        ForEach(data.ingredients) { ing in
                            Button {
                                sheet = .adjust(ing)
                            } label: {
                                StockRow(ing: ing)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)

                    if !data.stockEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent activity")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.textMuted)
                            ForEach(data.stockEntries.prefix(10)) { entry in
                                HStack {
                                    Circle().fill(entry.kind.color).frame(width: 8, height: 8)
                                    Text(entry.ingredientName)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text("· \(entry.kind.title.lowercased())")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textMuted)
                                    Spacer()
                                    Text("\(entry.grams >= 0 ? "+" : "")\(Int(entry.grams)) g")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(entry.kind.color)
                                }
                                .padding(.vertical, 6)
                                Divider().background(AppTheme.divider)
                            }
                        }
                        .cardStyle()
                        .padding(.horizontal, 18)
                    }

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Stock")
        .sheet(item: $sheet) { s in
            switch s {
            case .adjust(let i):
                StockAdjustSheet(ingredient: i)
            }
        }
    }
}

struct StockRow: View {
    let ing: Ingredient
    @EnvironmentObject var appState: AppState

    var body: some View {
        let progress = min(1, ing.grams / 5000)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "leaf.fill").foregroundColor(AppTheme.grainActive)
                Text(ing.name).font(.system(size: 14, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text(appState.formattedWeight(ing.grams))
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.earthDark)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.bgSoft).frame(height: 6)
                    Capsule().fill(AppTheme.grainGradient)
                        .frame(width: max(6, geo.size.width * CGFloat(progress)), height: 6)
                }
            }
            .frame(height: 6)
        }
        .ingredientCardStyle()
    }
}

struct StockAdjustSheet: View {
    let ingredient: Ingredient
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var data: DataStore
    @State private var amount: String = ""
    @State private var kind: StockChangeKind = .added

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Adjust Stock")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 26)).foregroundColor(AppTheme.earth)
                    }
                }
                Text(ingredient.name).font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: 8) {
                    ForEach(StockChangeKind.allCases, id: \.self) { k in
                        PillButton(title: k.title, isSelected: kind == k) { kind = k }
                    }
                }

                AppTextField(placeholder: "Grams", text: $amount, icon: "scalemass.fill", keyboard: .decimalPad)

                Spacer()
                PrimaryButton(title: "Apply", icon: "checkmark") {
                    let g = Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
                    let delta: Double
                    switch kind {
                    case .added: delta = g
                    case .used: delta = -g
                    case .adjusted: delta = g - ingredient.grams
                    }
                    data.adjustStock(ingredientId: ingredient.id, deltaGrams: delta, kind: kind)
                    dismiss()
                }
                .padding(.bottom, 24)
            }
            .padding(20).padding(.top, 8)
        }
    }
}

struct OptimizationView: View {
    @EnvironmentObject var data: DataStore
    @EnvironmentObject var appState: AppState

    private var tips: [(String, String, String, Color)] {
        var list: [(String, String, String, Color)] = []
        let cheapest = data.ingredients.min(by: { $0.pricePerKg < $1.pricePerKg })
        if let c = cheapest {
            list.append((
                "Use cheaper energy source",
                "\(c.name) is your cheapest base — use it as the bulk of your mix.",
                "leaf.arrow.circlepath", AppTheme.health
            ))
        }
        let lowProtein = data.ingredients.filter { $0.proteinPct < 12 }.count
        if lowProtein > 2 {
            list.append((
                "Balance with high-protein items",
                "You have many low-protein items. Add soybean or fish meal to balance.",
                "scalemass.fill", AppTheme.protein
            ))
        }
        let lowVitamin = data.ingredients.allSatisfy { $0.vitaminsPct < 5 }
        if lowVitamin {
            list.append((
                "Add a vitamin premix",
                "All ingredients are vitamin-poor. A small premix prevents deficiencies.",
                "pills.fill", AppTheme.vitamins
            ))
        }
        list.append((
            "Buy in bulk",
            "Buying base grains in 25kg+ bags can cut price/kg by up to 20%.",
            "shippingbox.fill", AppTheme.grainActive
        ))
        list.append((
            "Reduce waste",
            "Use covered feeders to avoid spoilage and rodent loss.",
            "trash.slash.fill", AppTheme.statusBad
        ))
        return list
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(spacing: 12) {
                    SectionHeader(title: "Optimization", subtitle: "Save money, improve nutrition")
                        .padding(.horizontal, 18).padding(.top, 6)

                    ForEach(0..<tips.count, id: \.self) { i in
                        let t = tips[i]
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14).fill(t.3.opacity(0.18)).frame(width: 44, height: 44)
                                Image(systemName: t.2).foregroundColor(t.3)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(t.0).font(.system(size: 15, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                                Text(t.1).font(.system(size: 12)).foregroundColor(AppTheme.textMuted)
                            }
                        }
                        .cardStyle()
                        .padding(.horizontal, 18)
                    }
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Optimization")
    }
}
