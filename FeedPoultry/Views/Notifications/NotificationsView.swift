import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notifications: NotificationManager
    @EnvironmentObject var store: DataStore
    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var statusMessage: String = ""

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard
                    if !statusMessage.isEmpty {
                        statusBanner
                    }

                    SectionHeader(title: "Daily Reminder", subtitle: "One ping each day at your set hour")
                    dailyReminderCard

                    SectionHeader(title: "Test", subtitle: "Make sure it works on this device")
                    PrimaryButton(title: "Send Test Notification", icon: "paperplane.fill") {
                        notifications.sendTestNotification()
                        statusMessage = "Test sent. Check the lock screen in a few seconds."
                    }

                    SectionHeader(title: "Scheduled Tasks", subtitle: "From your feeding schedule")
                    scheduledTasksCard
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Notifications")
        .onAppear { refreshStatus() }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.grainGradient)
                        .frame(width: 52, height: 52)
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.earthDark)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stay on schedule")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(authStatusLabel)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
            }

            Toggle(isOn: $appState.notificationsEnabled) {
                Text("Enable notifications")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .toggleStyle(SwitchToggleStyle(tint: AppTheme.healthMain))
            .onChange(of: appState.notificationsEnabled) { newValue in
                if newValue {
                    notifications.requestAuthorization { granted in
                        if granted {
                            notifications.scheduleDailyReminder(hour: appState.dailyReminderHour)
                            statusMessage = "Notifications enabled."
                        } else {
                            appState.notificationsEnabled = false
                            statusMessage = "Permission denied. Enable it in System Settings."
                        }
                        refreshStatus()
                    }
                } else {
                    notifications.cancel(identifier: "fp.daily.reminder")
                    statusMessage = "Notifications disabled."
                }
            }
        }
        .cardStyle()
    }

    private var statusBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(AppTheme.healthMain)
            Text(statusMessage)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.healthSoft.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.healthMain.opacity(0.4), lineWidth: 1)
        )
    }

    private var dailyReminderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Reminder hour")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text(String(format: "%02d:00", appState.dailyReminderHour))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.earthDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(AppTheme.grainHighlight))
            }
            Slider(
                value: Binding(
                    get: { Double(appState.dailyReminderHour) },
                    set: { appState.dailyReminderHour = Int($0) }
                ),
                in: 0...23,
                step: 1
            )
            .accentColor(AppTheme.grainActive)
            .onChange(of: appState.dailyReminderHour) { newHour in
                if appState.notificationsEnabled {
                    notifications.scheduleDailyReminder(hour: newHour)
                    statusMessage = "Daily reminder rescheduled for \(String(format: "%02d:00", newHour))."
                }
            }

            HStack {
                ForEach([6, 9, 12, 15, 18, 21], id: \.self) { hour in
                    PillButton(
                        title: String(format: "%02d", hour),
                        isSelected: appState.dailyReminderHour == hour
                    ) {
                        appState.dailyReminderHour = hour
                    }
                }
            }
        }
        .cardStyle()
    }

    private var scheduledTasksCard: some View {
        let upcoming = store.tasks.filter { !$0.isDone && $0.notify }
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .prefix(5)

        return VStack(spacing: 0) {
            if upcoming.isEmpty {
                EmptyState(icon: "bell.slash", title: "No scheduled reminders", subtitle: "Add tasks with notifications turned on")
                    .padding(.vertical, 14)
            } else {
                ForEach(Array(upcoming.enumerated()), id: \.element.id) { idx, task in
                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(AppTheme.grainActive)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(AppTheme.grainHighlight))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text(formattedDate(task.scheduledAt))
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Text(task.recurrence.displayName)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(AppTheme.healthSoft.opacity(0.25)))
                            .foregroundColor(AppTheme.healthActive)
                    }
                    .padding(.vertical, 10)
                    if idx < upcoming.count - 1 {
                        Divider().background(AppTheme.divider)
                    }
                }
            }
        }
        .cardStyle()
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d • HH:mm"
        return f.string(from: date)
    }

    private var authStatusLabel: String {
        switch authStatus {
        case .authorized: return "System permission granted"
        case .denied: return "Permission denied — open Settings to allow"
        case .notDetermined: return "Permission not requested yet"
        case .provisional: return "Provisional permission"
        case .ephemeral: return "Ephemeral access"
        @unknown default: return "Unknown status"
        }
    }

    private func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authStatus = settings.authorizationStatus
            }
        }
    }
}
