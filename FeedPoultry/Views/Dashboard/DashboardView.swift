import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var data: DataStore
    @State private var greetingPulse = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header greeting
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hello, \(appState.userName)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textMuted)
                            Text(appState.farmName)
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        Spacer()
                        NavigationLink {
                            NotificationsView()
                        } label: {
                            ZStack {
                                Circle().fill(AppTheme.cardWhite).frame(width: 42, height: 42)
                                    .shadow(color: AppTheme.softShadow, radius: 5, y: 2)
                                Image(systemName: "bell.fill")
                                    .foregroundColor(AppTheme.earth)
                                if data.pendingTasksCount > 0 {
                                    Circle().fill(AppTheme.statusBad).frame(width: 10, height: 10)
                                        .offset(x: 12, y: -12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 4)

                    // Quick stats row
                    HStack(spacing: 12) {
                        StatTile(title: "Stock", value: appState.formattedWeight(data.totalStockGrams),
                                 icon: "shippingbox.fill", tint: AppTheme.grainActive)
                        StatTile(title: "Spent", value: appState.formattedMoney(data.totalSpent),
                                 icon: "dollarsign.circle.fill", tint: AppTheme.earth)
                    }
                    .padding(.horizontal, 18)

                    HStack(spacing: 12) {
                        StatTile(title: "Recipes", value: "\(data.recipes.count)",
                                 icon: "book.closed.fill", tint: AppTheme.health)
                        StatTile(title: "Tasks", value: "\(data.pendingTasksCount) pending",
                                 icon: "checklist", tint: AppTheme.birdWarm)
                    }
                    .padding(.horizontal, 18)

                    // Feed plans card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "leaf.fill").foregroundColor(AppTheme.health)
                            Text("Feed Plans").font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            NavigationLink {
                                CalculatorView()
                            } label: {
                                Text("New").font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AppTheme.earthDark)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Capsule().fill(AppTheme.grain))
                            }
                        }
                        if data.recipes.isEmpty {
                            Text("Build your first feed mix in the Calculator.")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textMuted)
                                .padding(.vertical, 4)
                        } else {
                            ForEach(data.recipes.prefix(3)) { r in
                                NavigationLink {
                                    RecipeDetailView(recipe: r)
                                } label: {
                                    RecipeRow(recipe: r)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .cardStyle()
                    .padding(.horizontal, 18)

                    // Costs summary
                    NavigationLink {
                        CostsView()
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "chart.pie.fill").foregroundColor(AppTheme.earth)
                                Text("Costs")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Total spent").font(.system(size: 11)).foregroundColor(AppTheme.textMuted)
                                    Text(appState.formattedMoney(data.totalSpent))
                                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Spacer()
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Stock value").font(.system(size: 11)).foregroundColor(AppTheme.textMuted)
                                    Text(appState.formattedMoney(data.totalStockValue))
                                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                                        .foregroundColor(AppTheme.health)
                                }
                            }
                        }
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)

                    // Bird health
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "heart.fill").foregroundColor(AppTheme.statusBad)
                            Text("Bird Health")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                        }
                        HStack(spacing: 10) {
                            ForEach(BirdType.allCases) { bt in
                                NavigationLink {
                                    BirdDetailView(birdType: bt)
                                } label: {
                                    VStack(spacing: 6) {
                                        Text(bt.emoji).font(.system(size: 30))
                                        Text(bt.title)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text("Healthy")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(AppTheme.health)
                                    }
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(AppTheme.cardWarm)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(AppTheme.divider, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .cardStyle()
                    .padding(.horizontal, 18)

                    // Quick actions
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick Actions")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            QuickActionCell(title: "Bird Types", icon: "bird.fill", tint: AppTheme.birdWarm) {
                                BirdTypesView()
                            }
                            QuickActionCell(title: "Ingredients", icon: "leaf.fill", tint: AppTheme.health) {
                                IngredientsView()
                            }
                            QuickActionCell(title: "Stock", icon: "shippingbox.fill", tint: AppTheme.earth) {
                                StockView()
                            }
                            QuickActionCell(title: "Reports", icon: "chart.bar.fill", tint: AppTheme.protein) {
                                ReportsView()
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct QuickActionCell<Destination: View>: View {
    let title: String
    let icon: String
    let tint: Color
    let destination: () -> Destination
    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(tint.opacity(0.18)).frame(width: 40, height: 40)
                    Image(systemName: icon).foregroundColor(tint).font(.system(size: 17, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.cardWhite)
                    .shadow(color: AppTheme.softShadow, radius: 6, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct RecipeRow: View {
    let recipe: Recipe
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(AppTheme.bgSoft).frame(width: 44, height: 44)
                Text(recipe.birdType.emoji).font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("\(recipe.goal.title) · \(recipe.ageWeeks) weeks")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(AppTheme.textMuted)
                .font(.system(size: 12, weight: .bold))
        }
        .padding(.vertical, 6)
    }
}
