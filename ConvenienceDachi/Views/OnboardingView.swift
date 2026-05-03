import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var step = 0
    @State private var selectedAmount = 300
    @State private var selectedTime = "21:00"

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $step) {
                OnboardingPage(
                    systemImage: "leaf.circle.fill",
                    title: "コンビニに寄らない日を増やしましょう",
                    message: "毎日の小さな出費を、無理なく見える化できます。"
                )
                .tag(0)

                ScrollView {
                    VStack(spacing: 18) {
                        Image(systemName: "yen.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.brandGreen)
                        Text("1回あたり、平均いくら使いますか？")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.ink)
                            .multilineTextAlignment(.center)
                        Text("コンビニに寄らなかった日の推定節約額に使います。")
                            .font(.headline)
                            .foregroundStyle(Color.mutedInk)
                            .multilineTextAlignment(.center)
                        Text("10円単位で調整できます。")
                            .font(.subheadline)
                            .foregroundStyle(Color.mutedInk)
                            .multilineTextAlignment(.center)

                        AverageSpendPickerControls(amount: $selectedAmount)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                }
                .tag(1)

                ScrollView {
                    VStack(spacing: 18) {
                        Image(systemName: "bell.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.brandGreen)
                        Text("いつ記録しますか？")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.ink)
                            .multilineTextAlignment(.center)
                        Text("夜に1回だけ、今日の記録を思い出せるようにします。")
                            .font(.headline)
                            .foregroundStyle(Color.mutedInk)
                            .multilineTextAlignment(.center)
                        Text("15分単位で調整できます。")
                            .font(.subheadline)
                            .foregroundStyle(Color.mutedInk)
                            .multilineTextAlignment(.center)

                        ReminderTimePickerControls(time: $selectedTime)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(step == 2 ? "はじめる" : "次へ") {
                if step < 2 {
                    withAnimation { step += 1 }
                } else {
                    var next = store.settings
                    next.averageSpendAmount = UserSettings.normalizedSpend(selectedAmount)
                    next.reminderTime = UserSettings.normalizedReminderTime(selectedTime)
                    store.settings = next
                    store.hasCompletedOnboarding = true
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .background(Color.warmSurface.ignoresSafeArea())
    }
}

struct OnboardingPage: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: systemImage)
                .font(.system(size: 74))
                .foregroundStyle(Color.brandGreen)
            Text(title)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.headline)
                .foregroundStyle(Color.mutedInk)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}
