import SwiftUI

struct BirdTypesView: View {
    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(spacing: 14) {
                    SectionHeader(title: "Bird Types",
                                  subtitle: "Choose a species to view feeding guidelines")
                        .padding(.horizontal, 18)
                        .padding(.top, 6)

                    ForEach(BirdType.allCases) { bt in
                        NavigationLink {
                            BirdDetailView(birdType: bt)
                        } label: {
                            BirdCard(birdType: bt)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 18)
                    }
                    Spacer(minLength: 80)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Bird Types")
    }
}

struct BirdCard: View {
    let birdType: BirdType
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.bgSoft)
                    .frame(width: 64, height: 64)
                Text(birdType.emoji).font(.system(size: 36))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(birdType.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Avg. \(Int(birdType.dailyFeedGrams))g feed / day")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted)
                HStack(spacing: 6) {
                    ForEach(FeedGoal.allCases) { goal in
                        Text(goal.title)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Capsule().fill(AppTheme.bgSoft))
                            .foregroundColor(AppTheme.earth)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(AppTheme.textMuted)
        }
        .cardStyle()
    }
}

struct BirdDetailView: View {
    let birdType: BirdType
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(AppTheme.cardWhite)
                            .shadow(color: AppTheme.softShadow, radius: 12, y: 6)
                            .frame(height: 220)
                        VStack(spacing: 6) {
                            Text(birdType.emoji).font(.system(size: 88))
                            Text(birdType.title)
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }

                    HStack(spacing: 12) {
                        StatTile(title: "Daily feed", value: appState.formattedWeight(birdType.dailyFeedGrams),
                                 icon: "leaf.fill", tint: AppTheme.health)
                        StatTile(title: "Group", value: birdType.title,
                                 icon: "bird.fill", tint: AppTheme.birdWarm)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommended ratios")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        ForEach(FeedGoal.allCases) { goal in
                            HStack {
                                Image(systemName: goal.icon)
                                    .foregroundColor(AppTheme.earthSoft)
                                Text(goal.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                Text("Protein \(Int(goal.targetProteinPct))%")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.protein)
                            }
                            .padding(.vertical, 6)
                            Divider().background(AppTheme.divider)
                        }
                    }
                    .cardStyle()

                    NavigationLink {
                        CalculatorView(initialBird: birdType)
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Build feed for this bird").fontWeight(.bold)
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(AppTheme.earthDark)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.grain))
                    }
                    .buttonStyle(.plain)
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
