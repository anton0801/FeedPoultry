import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var notifications: NotificationManager
    @State private var showResetConfirm = false
    @State private var resetMessage: String = ""

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionHeader(title: "Appearance", subtitle: "Theme applies immediately")
                    appearanceCard

                    SectionHeader(title: "Units", subtitle: "Used across the whole app")
                    unitsCard

                    SectionHeader(title: "Nutrition Standard", subtitle: "Sets ration targets")
                    nutritionCard

                    SectionHeader(title: "Notifications", subtitle: "Daily reminders and tasks")
                    notificationsCard

                    SectionHeader(title: "Data", subtitle: "Reset to defaults")
                    dataCard

                    if !resetMessage.isEmpty {
                        Text(resetMessage)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.healthActive)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 6)
                    }

                    SectionHeader(title: "About", subtitle: nil)
                    aboutCard
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Settings")
        .alert(isPresented: $showResetConfirm) {
            Alert(
                title: Text("Reset all data?"),
                message: Text("This removes recipes, ingredients, costs, tasks and history. Default ingredients will be restored."),
                primaryButton: .destructive(Text("Reset")) {
                    store.resetAll()
                    notifications.cancelAll()
                    if appState.notificationsEnabled {
                        notifications.scheduleDailyReminder(hour: appState.dailyReminderHour)
                    }
                    resetMessage = "All data was reset."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        resetMessage = ""
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(AppearanceMode.allCases) { mode in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            appState.appearance = mode
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(appState.appearance == mode ? AppTheme.earthDark : AppTheme.textSecondary)
                            Text(mode.displayName)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(appState.appearance == mode ? AppTheme.earthDark : AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(appState.appearance == mode ? AppTheme.grainHighlight : AppTheme.cardBg)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(appState.appearance == mode ? AppTheme.grainActive : AppTheme.divider, lineWidth: appState.appearance == mode ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }

    private var unitsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Weight")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                HStack(spacing: 8) {
                    ForEach(WeightUnit.allCases) { unit in
                        PillButton(title: unit.displayName, isSelected: appState.weightUnit == unit) {
                            appState.weightUnit = unit
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Currency")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                HStack(spacing: 8) {
                    ForEach(CurrencyCode.allCases) { code in
                        PillButton(title: code.symbol + " " + code.rawValue.uppercased(), isSelected: appState.currency == code) {
                            appState.currency = code
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private var nutritionCard: some View {
        VStack(spacing: 10) {
            ForEach(NutritionStandard.allCases) { std in
                Button {
                    appState.nutritionStandard = std
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(appState.nutritionStandard == std ? AppTheme.healthMain : AppTheme.divider, lineWidth: 2)
                                .frame(width: 22, height: 22)
                            if appState.nutritionStandard == std {
                                Circle()
                                    .fill(AppTheme.healthMain)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(std.displayName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text(std.description)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(appState.nutritionStandard == std ? AppTheme.healthSoft.opacity(0.18) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .cardStyle()
    }

    private var notificationsCard: some View {
        VStack(spacing: 14) {
            Toggle(isOn: $appState.notificationsEnabled) {
                HStack(spacing: 10) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(AppTheme.grainActive)
                    Text("Enable notifications")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: AppTheme.healthMain))
            .onChange(of: appState.notificationsEnabled) { newValue in
                if newValue {
                    notifications.requestAuthorization { granted in
                        if granted {
                            notifications.scheduleDailyReminder(hour: appState.dailyReminderHour)
                        } else {
                            appState.notificationsEnabled = false
                        }
                    }
                } else {
                    notifications.cancel(identifier: "fp.daily.reminder")
                }
            }

            if appState.notificationsEnabled {
                HStack {
                    Text("Daily reminder")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Stepper(
                        value: $appState.dailyReminderHour,
                        in: 0...23,
                        step: 1
                    ) {
                        Text(String(format: "%02d:00", appState.dailyReminderHour))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.earthDark)
                    }
                }
                .onChange(of: appState.dailyReminderHour) { newHour in
                    notifications.scheduleDailyReminder(hour: newHour)
                }

                Button {
                    notifications.sendTestNotification()
                } label: {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Send Test Notification")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(AppTheme.earthDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(AppTheme.grainHighlight))
                }
            }
        }
        .cardStyle()
    }

    private var dataCard: some View {
        VStack(spacing: 10) {
            Button {
                showResetConfirm = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset All Data")
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textInactive)
                }
                .foregroundColor(AppTheme.warningBad)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.warningBad.opacity(0.08))
                )
            }
        }
        .cardStyle()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Feed Poultry")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("v1.0.0")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Text("Optimize feed for healthier birds and lower costs.")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
        }
        .cardStyle()
    }
}
