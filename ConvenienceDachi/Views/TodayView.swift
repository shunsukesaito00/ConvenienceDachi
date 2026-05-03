import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingVisitedInput = false
    @State private var completion: CompletionKind?
    @State private var pendingAction: PendingAction?
    @State private var showingOverwriteAlert = false

    private var summary: MonthlySummary {
        store.summary()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Date().japaneseMonthDayWeekday)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.mutedInk)
                        Text("今日も寄らずに帰れた？")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.ink)
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            StreakBadge(days: summary.currentStreak)
                            Spacer()
                            Label("今月の推定節約額", systemImage: "sparkles")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.brandGreen)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            NumberUnitText(number: summary.estimatedSavings.formatted(), unit: "円")
                            Spacer(minLength: 8)
                        }

                        Text("寄らなかった分、少しずつ積み上がっています。")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.mutedInk)
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.07), radius: 18, y: 8)

                    VStack(spacing: 18) {
                        Text("今日コンビニ行った？")
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.ink)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Button("行かなかった") {
                            handle(.noConvenience)
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button("行った") {
                            handle(.visited)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 14, y: 6)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("今月の目標")
                                .font(.headline)
                            Spacer()
                            Text(goalText)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.brandNavy)
                        }

                        ProgressView(value: min(Double(summary.noConvenienceDays), Double(store.settings.monthlyGoalDays)), total: Double(store.settings.monthlyGoalDays))
                            .tint(Color.brandGreen)
                    }
                    .padding(18)
                    .background(Color.white.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    BannerAdPlaceholder()
                        .padding(.top, 4)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .background(Color.warmSurface.ignoresSafeArea())
            .navigationTitle("コンビニ断ち")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingVisitedInput) {
                VisitedInputView { amount, categories in
                    store.recordVisited(amount: amount, categories: categories)
                    showingVisitedInput = false
                    completion = .visited
                }
            }
            .navigationDestination(item: $completion) { kind in
                CompletionView(kind: kind)
            }
            .alert("今日はすでに記録済みです", isPresented: $showingOverwriteAlert, presenting: pendingAction) { action in
                Button("変更する") {
                    perform(action)
                }
                Button("キャンセル", role: .cancel) {}
            } message: { _ in
                Text("今日の記録を変更しますか？")
            }
        }
    }

    private func handle(_ action: PendingAction) {
        if store.todayRecord == nil {
            perform(action)
        } else {
            pendingAction = action
            showingOverwriteAlert = true
        }
    }

    private func perform(_ action: PendingAction) {
        switch action {
        case .noConvenience:
            store.recordNoConvenience()
            completion = .noConvenience
        case .visited:
            showingVisitedInput = true
        }
    }

    private var goalText: String {
        let remaining = max(0, store.settings.monthlyGoalDays - summary.noConvenienceDays)
        return remaining == 0 ? "達成" : "あと\(remaining)日"
    }
}

enum PendingAction: Identifiable {
    case noConvenience
    case visited

    var id: String { String(describing: self) }
}

enum CompletionKind: Identifiable, Hashable {
    case noConvenience
    case visited

    var id: String { String(describing: self) }
}
