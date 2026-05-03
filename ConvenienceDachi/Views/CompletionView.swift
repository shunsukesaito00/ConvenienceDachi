import SwiftUI
import StoreKit
import UIKit

struct CompletionView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var titleText = ""
    @State private var messageText = ""
    @State private var showsNumbers = false

    let kind: CompletionKind

    private var summary: MonthlySummary {
        store.summary()
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)

            Image(systemName: kind == .noConvenience ? "checkmark.seal.fill" : "pencil.and.list.clipboard")
                .font(.system(size: 64))
                .foregroundStyle(kind == .noConvenience ? Color.brandGreen : Color.gentleOrange)

            VStack(spacing: 10) {
                Text(titleText)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)
                Text(messageText)
                    .font(.headline)
                    .foregroundStyle(Color.mutedInk)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                MetricCard(title: kind == .noConvenience ? "今日の推定節約額" : "次の一歩", value: todaySavingText, systemImage: "yen.circle")
                MetricCard(title: "今月の推定節約額", value: "\(summary.estimatedSavings.formatted())円", systemImage: "chart.line.uptrend.xyaxis")
                MetricCard(title: "連続記録", value: "\(summary.currentStreak)日連続", systemImage: "flame")
            }
            .opacity(showsNumbers ? 1 : 0)
            .offset(y: showsNumbers ? 0 : 10)
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showsNumbers)

            if let milestoneText {
                Text(milestoneText)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.brandNavy)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.softGreen)
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            NavigationLink {
                if kind == .noConvenience {
                    CalendarScreen()
                } else {
                    ReportView()
                }
            } label: {
                Text(kind == .noConvenience ? "カレンダーを見る" : "レポートを見る")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button("閉じる") {
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(18)
        .background(Color.warmSurface.ignoresSafeArea())
        .navigationBarBackButtonHidden(false)
        .onAppear {
            let message = CompletionMessage.random(for: kind, averageSpendAmount: store.settings.averageSpendAmount)
            titleText = message.title
            messageText = message.body
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showsNumbers = true
            if store.shouldRequestReviewNow() {
                requestReview()
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { store.shouldPresentInterstitialAd },
            set: { if !$0 { store.interstitialWasDismissed() } }
        )) {
            InterstitialAdPlaceholder {
                store.interstitialWasDismissed()
            }
        }
    }

    private var todaySavingText: String {
        kind == .noConvenience ? "約\(store.settings.averageSpendAmount.formatted())円" : "明日また少し"
    }

    private var milestoneText: String? {
        guard kind == .noConvenience else { return nil }
        if summary.noConvenienceDays >= store.settings.monthlyGoalDays {
            return "月間目標達成"
        }
        if [3, 7, 14, 30].contains(summary.currentStreak) {
            return "\(summary.currentStreak)日連続"
        }
        return nil
    }
}

private enum CompletionMessage {
    static func random(for kind: CompletionKind, averageSpendAmount: Int) -> (title: String, body: String) {
        switch kind {
        case .noConvenience:
            return noConvenienceMessages(averageSpendAmount: averageSpendAmount).randomElement()!
        case .visited:
            return visitedMessages.randomElement()!
        }
    }

    private static func noConvenienceMessages(averageSpendAmount: Int) -> [(title: String, body: String)] {
        [
            ("今日の勝ちです", "約\(averageSpendAmount.formatted())円、未来の自分に残せました。"),
            ("寄らなかった分、残せました", "小さな節約が積み上がっています。"),
            ("今日も積み上がりました", "その一歩、ちゃんと記録に残っています。"),
            ("いいペースです", "無理なく続けられています。")
        ]
    }

    private static let visitedMessages: [(title: String, body: String)] = [
        ("今日は記録できました", "使ったことに気づけたのでOKです。"),
        ("まずは見える化できました", "明日また少し意識してみましょう。"),
        ("記録できただけで前進です", "その一歩、ちゃんと積み上がっています。"),
        ("今日の記録を残せました", "無理なく続けていきましょう。")
    ]
}
