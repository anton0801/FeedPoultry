import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var store: DataStore
    @State private var localName: String = ""
    @State private var localFarm: String = ""
    @State private var saved: Bool = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    avatarHeader

                    SectionHeader(title: "Account", subtitle: "Edit and save your details")
                    accountForm

                    SectionHeader(title: "Stats", subtitle: "Your farm at a glance")
                    statsCard

                    SectionHeader(title: "More", subtitle: nil)
                    NavigationLink(destination: ActivityHistoryView()) {
                        navRow(title: "Activity History", icon: "clock.arrow.circlepath", count: store.activity.count)
                    }
                    NavigationLink(destination: SettingsView()) {
                        navRow(title: "Settings", icon: "gearshape.fill", count: nil)
                    }

                    if appState.isLoggedIn {
                        Button {
                            appState.isLoggedIn = false
                            store.logActivity(title: "Logged out", detail: "", icon: "rectangle.portrait.and.arrow.right")
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Log Out")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(AppTheme.warningBad)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AppTheme.warningBad.opacity(0.1))
                            )
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            localName = appState.userName
            localFarm = appState.farmName
        }
    }

    private var avatarHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.grainGradient)
                    .frame(width: 96, height: 96)
                    .shadow(color: AppTheme.grainGlow, radius: 20, x: 0, y: 6)
                Text(initials)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.earthDark)
            }
            VStack(spacing: 4) {
                Text(appState.userName.isEmpty ? "Farmer" : appState.userName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(appState.farmName.isEmpty ? "Add your farm name" : appState.farmName)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var initials: String {
        let parts = appState.userName.split(separator: " ")
        if parts.isEmpty { return "FP" }
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? (parts.last?.prefix(1) ?? "") : ""
        return String(first + last).uppercased()
    }

    private var accountForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppTextField(label: "Name", text: $localName, placeholder: "Your name")
            AppTextField(label: "Farm Name", text: $localFarm, placeholder: "e.g. Sunny Acres")

            PrimaryButton(title: saved ? "Saved!" : "Save Profile", icon: saved ? "checkmark.circle.fill" : "square.and.arrow.down.fill") {
                appState.userName = localName.trimmingCharacters(in: .whitespaces)
                appState.farmName = localFarm.trimmingCharacters(in: .whitespaces)
                store.logActivity(title: "Profile updated", detail: appState.userName, icon: "person.crop.circle.badge.checkmark")
                withAnimation(.spring()) { saved = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    withAnimation { saved = false }
                }
            }
        }
        .cardStyle()
    }

    private var statsCard: some View {
        VStack(spacing: 0) {
            statRow("Recipes saved", value: "\(store.recipes.count)", icon: "tray.full.fill", tint: AppTheme.grainActive)
            Divider().background(AppTheme.divider)
            statRow("Ingredients in stock", value: "\(store.ingredients.count)", icon: "leaf.fill", tint: AppTheme.healthMain)
            Divider().background(AppTheme.divider)
            statRow("Total spent", value: appState.formattedMoney(store.totalSpent), icon: "dollarsign.circle.fill", tint: AppTheme.earthMain)
            Divider().background(AppTheme.divider)
            statRow("Tasks scheduled", value: "\(store.tasks.count)", icon: "calendar", tint: AppTheme.protein)
        }
        .cardStyle()
    }

    private func statRow(_ title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(tint)
                .frame(width: 32, height: 32)
                .background(Circle().fill(tint.opacity(0.15)))
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppTheme.earthDark)
        }
        .padding(.vertical, 12)
    }

    private func navRow(title: String, icon: String, count: Int?) -> some View {
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
            if let c = count {
                Text("\(c)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(AppTheme.bgSoft))
            }
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
