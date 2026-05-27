import SwiftUI

struct ActivityHistoryView: View {
    @EnvironmentObject var store: DataStore

    var groupedByDay: [(String, [ActivityEvent])] {
        let cal = Calendar.current
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"

        let groups = Dictionary(grouping: store.activity) { event -> Date in
            cal.startOfDay(for: event.date)
        }
        return groups
            .sorted { $0.key > $1.key }
            .map { (f.string(from: $0.key), $0.value.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.earthGradient)
                                .frame(width: 52, height: 52)
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recent activity")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("\(store.activity.count) events tracked")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        if !store.activity.isEmpty {
                            Button {
                                store.activity.removeAll()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(AppTheme.warningBad)
                                    .padding(8)
                                    .background(Circle().fill(AppTheme.warningBad.opacity(0.12)))
                            }
                        }
                    }
                    .cardStyle()

                    if store.activity.isEmpty {
                        EmptyState(icon: "tray", title: "Nothing here yet", subtitle: "Use the app to start tracking activity")
                            .cardStyle()
                    } else {
                        ForEach(groupedByDay, id: \.0) { day, events in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(day.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(AppTheme.textInactive)
                                    .padding(.leading, 4)
                                VStack(spacing: 0) {
                                    ForEach(Array(events.enumerated()), id: \.element.id) { idx, event in
                                        HStack(spacing: 12) {
                                            Image(systemName: event.icon)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(AppTheme.grainActive)
                                                .frame(width: 32, height: 32)
                                                .background(Circle().fill(AppTheme.grainHighlight))
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(event.title)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(AppTheme.textPrimary)
                                                if !event.detail.isEmpty {
                                                    Text(event.detail)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(AppTheme.textSecondary)
                                                }
                                            }
                                            Spacer()
                                            Text(formattedTime(event.date))
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(AppTheme.textInactive)
                                        }
                                        .padding(.vertical, 10)
                                        if idx < events.count - 1 {
                                            Divider().background(AppTheme.divider)
                                        }
                                    }
                                }
                                .cardStyle()
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Activity")
    }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
