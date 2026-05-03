import Foundation
import UserNotifications

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var records: [String: DailyRecord] = [:]
    @Published var settings: UserSettings = UserSettings() {
        didSet {
            saveSettings()
            guard !isBootstrapping, hasCompletedOnboarding else { return }
            Task { await scheduleReminderIfNeeded() }
        }
    }
    @Published var hasCompletedOnboarding: Bool = false {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: Keys.onboarding)
            guard !isBootstrapping, hasCompletedOnboarding else { return }
            Task { await scheduleReminderIfNeeded() }
        }
    }
    @Published private(set) var shouldPresentInterstitialAd = false

    private let defaults: UserDefaults
    private var isBootstrapping = true
    private var totalRecordCount = 0 {
        didSet { defaults.set(totalRecordCount, forKey: Keys.totalRecordCount) }
    }
    private var lastInterstitialRecordCount = 0 {
        didSet { defaults.set(lastInterstitialRecordCount, forKey: Keys.lastInterstitialRecordCount) }
    }
    private var hasRequestedReview = false {
        didSet { defaults.set(hasRequestedReview, forKey: Keys.hasRequestedReview) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
        isBootstrapping = false
    }

    var todayKey: String {
        Date().convenienceKey
    }

    var todayRecord: DailyRecord? {
        records[todayKey]
    }

    func recordNoConvenience(for date: Date = Date()) {
        upsertRecord(
            date: date,
            status: .noConvenience,
            amount: nil,
            categories: []
        )
    }

    func recordVisited(amount: Int?, categories: [PurchaseCategory], for date: Date = Date()) {
        upsertRecord(
            date: date,
            status: .visited,
            amount: amount,
            categories: categories
        )
    }

    func record(for date: Date) -> DailyRecord? {
        records[date.convenienceKey]
    }

    func setAverageSpendAmount(_ value: Int) {
        var next = settings
        let normalized = UserSettings.normalizedSpend(value)
        guard next.averageSpendAmount != normalized else { return }
        next.averageSpendAmount = normalized
        settings = next
    }

    func setReminderTime(_ value: String) {
        var next = settings
        let normalized = UserSettings.normalizedReminderTime(value)
        guard next.reminderTime != normalized else { return }
        next.reminderTime = normalized
        settings = next
    }

    func summary(for month: Date = Date()) -> MonthlySummary {
        let monthRecords = recordsForMonth(month)
        let noConvenienceDays = monthRecords.filter { $0.status == .noConvenience }.count
        let visited = monthRecords.filter { $0.status == .visited }
        let totalSpend = visited.compactMap(\.amount).reduce(0, +)
        let categoryCounts = Dictionary(grouping: visited.flatMap(\.categories), by: { $0 })
            .mapValues(\.count)
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key.rawValue < rhs.key.rawValue }
                return lhs.value > rhs.value
            }

        return MonthlySummary(
            month: month,
            noConvenienceDays: noConvenienceDays,
            visitedDays: visited.count,
            estimatedSavings: noConvenienceDays * settings.averageSpendAmount,
            totalSpend: totalSpend,
            currentStreak: currentStreak(),
            bestStreak: bestStreak(),
            categoryRanking: categoryCounts
        )
    }

    func comparison(for month: Date = Date()) -> MonthlyComparison {
        let calendar = Calendar.localGregorian
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: month) ?? month
        return MonthlyComparison(current: summary(for: month), previous: summary(for: previousMonth))
    }

    var annualizedSavings: Int {
        summary().estimatedSavings * 12
    }

    func recordsForMonth(_ date: Date) -> [DailyRecord] {
        let calendar = Calendar.localGregorian
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }

        return records.values
            .filter { record in
                guard let recordDate = DateFormatters.dayKey.date(from: record.date) else { return false }
                return interval.contains(recordDate)
            }
            .sorted { $0.date < $1.date }
    }

    func resetAllData() {
        isBootstrapping = true
        records = [:]
        hasCompletedOnboarding = false
        settings = UserSettings()
        defaults.removeObject(forKey: Keys.records)
        defaults.removeObject(forKey: Keys.settings)
        defaults.removeObject(forKey: Keys.onboarding)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        shouldPresentInterstitialAd = false
        totalRecordCount = 0
        lastInterstitialRecordCount = 0
        hasRequestedReview = false
        defaults.removeObject(forKey: Keys.totalRecordCount)
        defaults.removeObject(forKey: Keys.lastInterstitialRecordCount)
        defaults.removeObject(forKey: Keys.hasRequestedReview)
        isBootstrapping = false
    }

    func scheduleReminderIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Keys.reminderNotification])
        guard settings.reminderEnabled else { return }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            guard granted else { return }

            let parts = settings.reminderTime.split(separator: ":").compactMap { Int($0) }
            var components = DateComponents()
            components.hour = parts.first ?? 21
            components.minute = parts.dropFirst().first ?? 0

            let content = UNMutableNotificationContent()
            let message = Self.reminderMessages.randomElement() ?? Self.reminderMessages[0]
            content.title = message.title
            content.body = message.body
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: Keys.reminderNotification, content: content, trigger: trigger)
            try await center.add(request)
        } catch {
            print("Reminder scheduling failed: \(error.localizedDescription)")
        }
    }

    private func upsertRecord(date: Date, status: DailyStatus, amount: Int?, categories: [PurchaseCategory]) {
        let key = date.convenienceKey
        let now = Date()
        let createdAt = records[key]?.createdAt ?? now
        let isNewRecord = records[key] == nil
        records[key] = DailyRecord(
            date: key,
            status: status,
            amount: amount,
            categories: categories,
            memo: records[key]?.memo,
            createdAt: createdAt,
            updatedAt: now
        )
        saveRecords()
        registerRecordCompletion(isNewRecord: isNewRecord)
    }

    func interstitialWasDismissed() {
        shouldPresentInterstitialAd = false
    }

    func shouldRequestReviewNow() -> Bool {
        guard !hasRequestedReview else { return false }
        let summary = summary()
        guard totalRecordCount >= 5, summary.noConvenienceDays >= 3 else { return false }
        hasRequestedReview = true
        return true
    }

    private func currentStreak() -> Int {
        let calendar = Calendar.localGregorian
        var cursor = Date()
        var count = 0

        while let record = records[cursor.convenienceKey], record.status == .noConvenience {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return count
    }

    private func bestStreak() -> Int {
        let noConvenienceDates = Set(records.values.filter { $0.status == .noConvenience }.map(\.date))
        let sortedDates = noConvenienceDates.sorted()
        guard !sortedDates.isEmpty else { return 0 }

        var best = 0
        var current = 0
        var previousDate: Date?

        for key in sortedDates {
            guard let date = DateFormatters.dayKey.date(from: key) else { continue }
            if let previousDate,
               Calendar.localGregorian.isDate(date, inSameDayAs: Calendar.localGregorian.date(byAdding: .day, value: 1, to: previousDate) ?? date) {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previousDate = date
        }

        return best
    }

    private func load() {
        records = decode([String: DailyRecord].self, forKey: Keys.records) ?? [:]
        var loaded = decode(UserSettings.self, forKey: Keys.settings) ?? UserSettings()
        loaded.normalizeSpendAndReminder()
        settings = loaded
        hasCompletedOnboarding = defaults.bool(forKey: Keys.onboarding)
        totalRecordCount = defaults.integer(forKey: Keys.totalRecordCount)
        lastInterstitialRecordCount = defaults.integer(forKey: Keys.lastInterstitialRecordCount)
        hasRequestedReview = defaults.bool(forKey: Keys.hasRequestedReview)
    }

    private func saveRecords() {
        encode(records, forKey: Keys.records)
    }

    private func saveSettings() {
        encode(settings, forKey: Keys.settings)
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func registerRecordCompletion(isNewRecord: Bool) {
        if isNewRecord {
            totalRecordCount += 1
        }

        guard hasCompletedOnboarding,
              !settings.adsRemoved,
              settings.interstitialFrequency > 0,
              totalRecordCount > 0,
              totalRecordCount - lastInterstitialRecordCount >= settings.interstitialFrequency else { return }

        lastInterstitialRecordCount = totalRecordCount
        shouldPresentInterstitialAd = true
    }

    private static let reminderMessages: [(title: String, body: String)] = [
        ("今日コンビニ行った？", "30秒で記録できます。"),
        ("今日のコンビニ断ち", "記録しておきましょう。"),
        ("寄らなかった日は成果です", "今日の記録も、軽く残しておきましょう。"),
        ("帰り道の小さな出費", "今日はどうでしたか？"),
        ("今日の記録を残しましょう", "積み上げが見えるようになります。")
    ]
}

private enum Keys {
    static let records = "daily_records"
    static let settings = "user_settings"
    static let onboarding = "has_completed_onboarding"
    static let reminderNotification = "daily_convenience_reminder"
    static let totalRecordCount = "total_record_count"
    static let lastInterstitialRecordCount = "last_interstitial_record_count"
    static let hasRequestedReview = "has_requested_review"
}
