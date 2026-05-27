import SwiftUI

@main
struct FeedPoultryApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var dataStore = DataStore()
    @StateObject private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(dataStore)
                .environmentObject(notificationManager)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @State private var isShowingSplash: Bool = true

    var body: some View {
        ZStack {
            if isShowingSplash {
                SplashView(isShowingSplash: $isShowingSplash)
                    .transition(.opacity)
            } else if !hasCompletedOnboarding {
                OnboardingFlowView()
                    .transition(.opacity)
            } else if !isLoggedIn {
                WelcomeView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: isShowingSplash)
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: isLoggedIn)
    }
}
