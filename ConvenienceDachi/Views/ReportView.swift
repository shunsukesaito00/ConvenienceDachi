import SwiftUI

struct ReportView: View {
    @EnvironmentObject private var store: AppStore

    private var summary: MonthlySummary {
        store.summary()
    }

    private var comparison: MonthlyComparison {
        store.comparison()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("今月はいいペースです。小さな節約が積み上がっています。")
                        .font(.headline)
                        .foregroundStyle(Color.ink)
                        .padding(16)
                        .background(Color.softGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    MetricCard(title: "今月の推定節約額", value: "\(summary.estimatedSavings.formatted())円", systemImage: "yen.circle")
                    MetricCard(title: "コンビニ断ち日数", value: "\(summary.noConvenienceDays)日 / \(daysInCurrentMonth)日", systemImage: "checkmark.circle")
                    MetricCard(title: "行った日", value: "\(summary.visitedDays)日", systemImage: "figure.walk")
                    MetricCard(title: "コンビニ支出", value: "\(summary.totalSpend.formatted())円", systemImage: "cart")
                    MetricCard(title: "現在の連続記録", value: "\(summary.currentStreak)日", systemImage: "flame")
                    MetricCard(title: "最高連続記録", value: "\(summary.bestStreak)日", systemImage: "star")
                    MetricCard(title: "年間換算節約額", value: "約\(store.annualizedSavings.formatted())円", footnote: "今月ペースの目安", systemImage: "calendar.badge.clock")

                    VStack(alignment: .leading, spacing: 12) {
                        Label("月別比較", systemImage: "arrow.left.arrow.right")
                            .font(.headline)
                        ComparisonRow(title: "コンビニ断ち日数", value: signedDays(comparison.noConvenienceDifference))
                        ComparisonRow(title: "推定節約額", value: signedYen(comparison.savingsDifference))
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Label("よく買ったもの", systemImage: "list.number")
                            .font(.headline)
                        if summary.categoryRanking.isEmpty {
                            Text("記録が増えると、ここに表示されます。")
                                .foregroundStyle(Color.mutedInk)
                        } else {
                            ForEach(Array(summary.categoryRanking.prefix(3).enumerated()), id: \.element.0) { index, item in
                                HStack {
                                    Text("\(index + 1). \(item.0.rawValue)")
                                    Spacer()
                                    Text("\(item.1)回")
                                        .foregroundStyle(Color.mutedInk)
                                }
                                .font(.body.weight(.medium))
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    BannerAdPlaceholder()
                }
                .padding(18)
            }
            .background(Color.warmSurface.ignoresSafeArea())
            .navigationTitle("レポート")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var daysInCurrentMonth: Int {
        Calendar.localGregorian.range(of: .day, in: .month, for: Date())?.count ?? 31
    }

    private func signedYen(_ value: Int) -> String {
        if value > 0 { return "+\(value.formatted())円" }
        if value < 0 { return "-\(abs(value).formatted())円" }
        return "±0円"
    }

    private func signedDays(_ value: Int) -> String {
        if value > 0 { return "+\(value)日" }
        if value < 0 { return "-\(abs(value))日" }
        return "±0日"
    }
}

private struct ComparisonRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.ink)
            Spacer()
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(value.hasPrefix("-") ? Color.gentleOrange : Color.brandGreen)
        }
    }
}
