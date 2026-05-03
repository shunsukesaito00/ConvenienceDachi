import Foundation

extension Calendar {
    static var localGregorian: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        calendar.timeZone = .current
        return calendar
    }
}

extension Date {
    var convenienceKey: String {
        DateFormatters.dayKey.string(from: self)
    }

    var japaneseMonthDayWeekday: String {
        DateFormatters.monthDayWeekday.string(from: self)
    }

    var japaneseFullDate: String {
        DateFormatters.fullDate.string(from: self)
    }
}

enum DateFormatters {
    static let dayKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .localGregorian
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let monthDayWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .localGregorian
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = .current
        formatter.dateFormat = "M月d日（E）"
        return formatter
    }()

    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .localGregorian
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy年M月d日（E）"
        return formatter
    }()
}
