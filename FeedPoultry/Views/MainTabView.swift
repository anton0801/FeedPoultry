import SwiftUI

enum AppTab: String, Hashable, CaseIterable {
    case dashboard, calculator, recipes, more

    var title: String {
        switch self {
        case .dashboard: return "Home"
        case .calculator: return "Mix"
        case .recipes: return "Recipes"
        case .more: return "More"
        }
    }
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .calculator: return "slider.horizontal.3"
        case .recipes: return "book.fill"
        case .more: return "square.grid.2x2.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selected: AppTab = .dashboard

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Group {
                    switch selected {
                    case .dashboard:  NavigationView { DashboardView() }
                    case .calculator: NavigationView { CalculatorView() }
                    case .recipes:    NavigationView { RecipesView() }
                    case .more:       NavigationView { MoreView() }
                    }
                }
                .navigationViewStyle(.stack)
                Spacer().frame(height: 40)
            }

            CustomTabBar(selected: $selected)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selected: AppTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        ZStack {
                            if selected == tab {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AppTheme.grain)
                                    .frame(width: 50, height: 32)
                                    .shadow(color: AppTheme.yellowGlow, radius: 8, y: 3)
                            }
                            Image(systemName: tab.icon)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(selected == tab ? AppTheme.earthDark : AppTheme.textMuted)
                        }
                        .frame(height: 32)
                        Text(tab.title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(selected == tab ? AppTheme.earthDark : AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.cardWhite)
                .shadow(color: AppTheme.softShadow, radius: 14, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.bgSoft, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
}
