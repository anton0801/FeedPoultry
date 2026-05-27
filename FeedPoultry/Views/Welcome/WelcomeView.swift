import SwiftUI

struct WelcomeView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("userName")   private var userName: String = "Farmer"
    @State private var showLogin: Bool = false
    @State private var bobbing = false
    @State private var isVisible = true

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(spacing: 28) {
                Spacer(minLength: 20)
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppTheme.grainGlow.opacity(0.55), .clear],
                                center: .center, startRadius: 10, endRadius: 180
                            )
                        )
                        .frame(width: 320, height: 320)
                    ChickenIllustration()
                        .frame(width: 200, height: 200)
                        .offset(y: bobbing ? -8 : 0)
                }
                .onAppear {
                    isVisible = true
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                        bobbing = true
                    }
                }
                .onDisappear {
                    isVisible = false
                    bobbing = false
                }

                VStack(spacing: 8) {
                    Text("Feed Poultry")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Smart feed plans for healthy birds")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.textMuted)
                }

                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(title: "Start", icon: "arrow.right.circle.fill") {
                        userName = "Farmer"
                        withAnimation(.easeInOut) { isLoggedIn = true }
                    }
                    SecondaryButton(title: "Log In", icon: "person.circle") {
                        showLogin = true
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginSheet()
        }
    }
}

private struct LoginSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("userName")   private var userName: String = "Farmer"
    @State private var name: String = ""
    @State private var password: String = ""
    @State private var error: String? = nil

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 18) {
                HStack {
                    Text("Log In")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(AppTheme.earth)
                    }
                }
                .padding(.top, 24)

                AppTextField(placeholder: "Username (try: demo)", text: $name, icon: "person.fill")
                AppTextField(placeholder: "Password (try: demo)", text: $password, icon: "lock.fill")

                if let error {
                    Text(error)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.statusBad)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("Demo account: demo / demo")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                PrimaryButton(title: "Log In", icon: "arrow.right") {
                    if name.lowercased() == "demo" && password.lowercased() == "demo" {
                        userName = "Demo Farmer"
                        isLoggedIn = true
                        dismiss()
                    } else if !name.isEmpty && !password.isEmpty {
                        userName = name
                        isLoggedIn = true
                        dismiss()
                    } else {
                        error = "Please enter username and password."
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 22)
        }
    }
}
