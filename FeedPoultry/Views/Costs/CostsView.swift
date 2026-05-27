import SwiftUI

struct CostsView: View {
    @EnvironmentObject var data: DataStore
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false

    private var byCategory: [(String, Double)] {
        var dict: [String: Double] = [:]
        for c in data.costs {
            dict[c.category, default: 0] += c.amount
        }
        return dict.sorted { $0.value > $1.value }
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(spacing: 12) {
                    HStack {
                        SectionHeader(title: "Costs", subtitle: "Total: \(appState.formattedMoney(data.totalSpent))")
                        Button { showAdd = true } label: {
                            ZStack {
                                Circle().fill(AppTheme.grain).frame(width: 40, height: 40)
                                Image(systemName: "plus").font(.system(size: 18, weight: .heavy))
                                    .foregroundColor(AppTheme.earthDark)
                            }
                        }
                    }
                    .padding(.horizontal, 18).padding(.top, 6)

                    if !byCategory.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("By category").font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.textMuted)
                            ForEach(byCategory, id: \.0) { item in
                                let pct = data.totalSpent > 0 ? item.1 / data.totalSpent : 0
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(item.0).font(.system(size: 14, weight: .bold))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Spacer()
                                        Text(appState.formattedMoney(item.1))
                                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                                            .foregroundColor(AppTheme.earthDark)
                                    }
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(AppTheme.bgSoft).frame(height: 6)
                                            Capsule().fill(AppTheme.grainGradient)
                                                .frame(width: max(6, geo.size.width * CGFloat(pct)), height: 6)
                                        }
                                    }
                                    .frame(height: 6)
                                }
                            }
                        }
                        .cardStyle()
                        .padding(.horizontal, 18)
                    }

                    if data.costs.isEmpty {
                        EmptyState(icon: "dollarsign.circle.fill",
                                   title: "No costs yet",
                                   message: "Add expenses to track your farm budget.")
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("All entries")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.textMuted)
                            ForEach(data.costs) { c in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(AppTheme.bgSoft).frame(width: 36, height: 36)
                                        Image(systemName: "dollarsign").foregroundColor(AppTheme.earth)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(c.title).font(.system(size: 14, weight: .bold))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text("\(c.category) · \(c.date.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.system(size: 11))
                                            .foregroundColor(AppTheme.textMuted)
                                    }
                                    Spacer()
                                    Text(appState.formattedMoney(c.amount))
                                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                                        .foregroundColor(AppTheme.earthDark)
                                    Button {
                                        if let idx = data.costs.firstIndex(where: { $0.id == c.id }) {
                                            data.deleteCost(at: IndexSet(integer: idx))
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(AppTheme.textMuted)
                                    }
                                }
                                .padding(.vertical, 4)
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
        .navigationTitle("Costs")
        .sheet(isPresented: $showAdd) {
            AddCostSheet()
        }
    }
}

struct AddCostSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var data: DataStore
    @State private var title = ""
    @State private var amount = ""
    @State private var category = "Feed"
    private let categories = ["Feed", "Supplements", "Medicine", "Equipment", "Other"]

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Add Cost").font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 26))
                            .foregroundColor(AppTheme.earth)
                    }
                }
                AppTextField(placeholder: "Title", text: $title, icon: "textformat")
                AppTextField(placeholder: "Amount", text: $amount, icon: "dollarsign.circle.fill", keyboard: .decimalPad)

                Text("Category").font(.system(size: 13, weight: .bold)).foregroundColor(AppTheme.textMuted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(categories, id: \.self) { c in
                            PillButton(title: c, isSelected: category == c) { category = c }
                        }
                    }
                }

                Spacer()
                PrimaryButton(title: "Add", icon: "checkmark") {
                    let amt = Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
                    let final = title.trimmingCharacters(in: .whitespaces).isEmpty ? "Expense" : title
                    data.addCost(CostRecord(title: final, amount: amt, category: category))
                    dismiss()
                }
                .padding(.bottom, 24)
            }
            .padding(20).padding(.top, 8)
        }
    }
}
