import Foundation

enum DailyStatus: String, Codable {
    case noConvenience = "no_convenience"
    case visited
}

enum PurchaseCategory: String, CaseIterable, Codable, Identifiable {
    case drink = "飲み物"
    case snack = "お菓子"
    case meal = "弁当"
    case coffee = "コーヒー"
    case other = "その他"

    var id: String { rawValue }
}

struct DailyRecord: Codable, Identifiable, Equatable {
    let date: String
    var status: DailyStatus
    var amount: Int?
    var categories: [PurchaseCategory]
    var memo: String?
    var createdAt: Date
    var updatedAt: Date

    var id: String { date }
}

struct UserSettings: Codable, Equatable {
    var averageSpendAmount: Int = 300
    var reminderEnabled: Bool = true
    var reminderTime: String = "21:00"
    var monthlyGoalDays: Int = 10
    var interstitialFrequency: Int = 3
    var adsRemoved: Bool = false

    /// 100〜3000円・10円刻み（UI・保存の共通仕様）
    static func normalizedSpend(_ value: Int) -> Int {
        let stepped = (value / 10) * 10
        return min(3000, max(100, stepped))
    }

    /// 0:00〜23:45・15分刻みの `HH:mm`
    static func normalizedReminderTime(_ raw: String) -> String {
        let parts = raw.split(separator: ":").compactMap { Int($0) }
        guard let hourPart = parts.first else { return "21:00" }
        let h = min(23, max(0, hourPart))
        let mRaw = parts.count > 1 ? parts[1] : 0
        let totalMinutes = h * 60 + mRaw
        let snapped = ((totalMinutes + 7) / 15) * 15
        let capped = min(23 * 60 + 45, max(0, snapped))
        let nh = capped / 60
        let nm = capped % 60
        return String(format: "%02d:%02d", nh, nm)
    }

    static var allValidSpendAmounts: [Int] {
        Array(stride(from: 100, through: 3000, by: 10))
    }

    static var allQuarterHourTimeStrings: [String] {
        (0..<24).flatMap { hour in
            [0, 15, 30, 45].map { minute in
                String(format: "%02d:%02d", hour, minute)
            }
        }
    }

    mutating func normalizeSpendAndReminder() {
        averageSpendAmount = Self.normalizedSpend(averageSpendAmount)
        reminderTime = Self.normalizedReminderTime(reminderTime)
    }
}

struct MonthlySummary {
    var month: Date
    var noConvenienceDays: Int
    var visitedDays: Int
    var estimatedSavings: Int
    var totalSpend: Int
    var currentStreak: Int
    var bestStreak: Int
    var categoryRanking: [(PurchaseCategory, Int)]
}

struct MonthlyComparison {
    var current: MonthlySummary
    var previous: MonthlySummary

    var savingsDifference: Int {
        current.estimatedSavings - previous.estimatedSavings
    }

    var noConvenienceDifference: Int {
        current.noConvenienceDays - previous.noConvenienceDays
    }
}
