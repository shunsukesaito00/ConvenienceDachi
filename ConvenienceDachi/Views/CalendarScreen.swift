import SwiftUI

struct CalendarScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var month = Date()
    @State private var selectedDate = Date()

    private var calendar: Calendar { .localGregorian }
    private var summary: MonthlySummary { store.summary(for: month) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Button {
                            changeMonth(-1)
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .frame(width: 44, height: 44)

                        Spacer()

                        Text(monthTitle)
                            .font(.system(.title3, design: .rounded).weight(.bold))

                        Spacer()

                        Button {
                            changeMonth(1)
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .frame(width: 44, height: 44)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(title: "推定節約額", value: "\(summary.estimatedSavings.formatted())円", systemImage: "yen.circle")
                        MetricCard(title: "コンビニ断ち", value: "\(summary.noConvenienceDays)日", systemImage: "checkmark.circle")
                        MetricCard(title: "行った日", value: "\(summary.visitedDays)日", systemImage: "cart")
                    }

                    VStack(spacing: 10) {
                        HStack {
                            ForEach(["月", "火", "水", "木", "金", "土", "日"], id: \.self) { weekday in
                                Text(weekday)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.mutedInk)
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                            ForEach(calendarCells, id: \.self) { date in
                                if let date {
                                    DayCell(
                                        date: date,
                                        record: store.record(for: date),
                                        isToday: calendar.isDateInToday(date),
                                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                                    ) {
                                        selectedDate = date
                                    }
                                } else {
                                    Color.clear
                                        .frame(height: 42)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    selectedDetail
                }
                .padding(18)
            }
            .background(Color.warmSurface.ignoresSafeArea())
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: month)
    }

    private var calendarCells: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let dayRange = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leading = (firstWeekday + 5) % 7
        let days = dayRange.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: interval.start)
        }
        return Array(repeating: nil, count: leading) + days
    }

    private var selectedDetail: some View {
        let record = store.record(for: selectedDate)
        return VStack(alignment: .leading, spacing: 10) {
            Text("選択日：\(selectedDate.japaneseMonthDayWeekday)")
                .font(.headline)
            if let record {
                switch record.status {
                case .noConvenience:
                    Text("行かなかった")
                    Text("約\(store.settings.averageSpendAmount.formatted())円節約")
                case .visited:
                    Text("行った")
                    Text(record.amount.map { "支出 \($0.formatted())円" } ?? "支出 未入力")
                    if !record.categories.isEmpty {
                        Text("買ったもの：\(record.categories.map(\.rawValue).joined(separator: "、"))")
                    }
                }
            } else {
                Text("未記録")
                    .foregroundStyle(Color.mutedInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func changeMonth(_ value: Int) {
        month = calendar.date(byAdding: .month, value: value, to: month) ?? month
    }
}

struct DayCell: View {
    let date: Date
    let record: DailyRecord?
    let isToday: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text("\(Calendar.localGregorian.component(.day, from: date))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.mutedInk)
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(symbolColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(backgroundColor)
            .overlay(
                Circle()
                    .stroke(borderColor, lineWidth: isSelected ? 2.5 : 1.5)
            )
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var systemImage: String {
        guard let record else { return "circle" }
        return record.status == .noConvenience ? "checkmark" : "minus"
    }

    private var symbolColor: Color {
        guard let record else { return .clear }
        return record.status == .noConvenience ? .white : .mutedInk
    }

    private var backgroundColor: Color {
        guard let record else { return .white }
        return record.status == .noConvenience ? .brandGreen : Color.black.opacity(0.05)
    }

    private var borderColor: Color {
        if isSelected { return .brandNavy }
        if isToday { return .brandGreen }
        if record == nil { return Color.black.opacity(0.12) }
        return .clear
    }
}
