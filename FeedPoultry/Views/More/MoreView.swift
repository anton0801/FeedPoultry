import SwiftUI

struct MoreView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var store: DataStore

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    profileCard

                    SectionHeader(title: "Inventory", subtitle: nil)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        NavigationLink(destination: BirdTypesView()) {
                            MoreTile(title: "Bird Types", icon: "bird.fill", tint: AppTheme.birdWarm, count: BirdType.allCases.count)
                        }
                        NavigationLink(destination: IngredientsView()) {
                            MoreTile(title: "Ingredients", icon: "leaf.fill", tint: AppTheme.healthMain, count: store.ingredients.count)
                        }
                        NavigationLink(destination: StockView()) {
                            MoreTile(title: "Stock", icon: "shippingbox.fill", tint: AppTheme.earthMain, count: store.ingredients.count)
                        }
                        NavigationLink(destination: CostsView()) {
                            MoreTile(title: "Costs", icon: "dollarsign.circle.fill", tint: AppTheme.protein, count: store.costs.count)
                        }
                    }

                    SectionHeader(title: "Productivity", subtitle: nil)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        NavigationLink(destination: TasksView()) {
                            MoreTile(title: "Tasks", icon: "checklist", tint: AppTheme.grainActive, count: store.tasks.filter { !$0.isDone }.count)
                        }
                        NavigationLink(destination: ReportsView()) {
                            MoreTile(title: "Reports", icon: "chart.bar.fill", tint: AppTheme.fat, count: nil)
                        }
                        NavigationLink(destination: NotificationsView()) {
                            MoreTile(title: "Notifications", icon: "bell.fill", tint: AppTheme.grainActive, count: nil)
                        }
                        NavigationLink(destination: ActivityHistoryView()) {
                            MoreTile(title: "Activity", icon: "clock.arrow.circlepath", tint: AppTheme.earthDark, count: store.activity.count)
                        }
                    }

                    SectionHeader(title: "App", subtitle: nil)
                    VStack(spacing: 10) {
                        NavigationLink(destination: ProfileView()) {
                            navRow(title: "Profile", icon: "person.crop.circle.fill")
                        }
                        NavigationLink(destination: SettingsView()) {
                            navRow(title: "Settings", icon: "gearshape.fill")
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("More")
    }

    private var profileCard: some View {
        NavigationLink(destination: ProfileView()) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.grainGradient)
                        .frame(width: 56, height: 56)
                    Text(initials)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.earthDark)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.userName.isEmpty ? "Farmer" : appState.userName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(appState.farmName.isEmpty ? "Tap to edit profile" : appState.farmName)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textInactive)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private var initials: String {
        let parts = appState.userName.split(separator: " ")
        if parts.isEmpty { return "FP" }
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? (parts.last?.prefix(1) ?? "") : ""
        return String(first + last).uppercased()
    }

    private func navRow(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppTheme.earthDark)
                .frame(width: 36, height: 36)
                .background(Circle().fill(AppTheme.grainHighlight))
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.textInactive)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.divider, lineWidth: 1)
        )
    }
}

struct MoreTile: View {
    let title: String
    let icon: String
    let tint: Color
    let count: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(tint)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                if let c = count {
                    Text("\(c) items")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                } else {
                    Text("Tap to open")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.divider, lineWidth: 1)
        )
    }
}
