import SwiftUI

enum WeekStart {
    case sunday
    case monday
}

struct ThreeMonthCalendarView: View {
    let referenceDate: Date
    let weekStart: WeekStart
    let holidays: HolidayCalendar

    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.locale = Locale(identifier: "en_US_POSIX")
        return cal
    }()

    private var monthDates: [Date] {
        let currentMonth = startOfMonth(for: referenceDate)
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        return [previousMonth, currentMonth, nextMonth]
    }

    var body: some View {
        GeometryReader { proxy in
            let columnWidth = proxy.size.width / 3
            HStack(spacing: 6) {
                ForEach(monthDates, id: \.self) { monthDate in
                    MonthCalendarView(
                        monthDate: monthDate,
                        referenceDate: referenceDate,
                        weekStart: weekStart,
                        calendar: calendar,
                        holidays: holidays
                    )
                    .frame(width: columnWidth)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(6)
        }
    }

    private func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
}

private struct MonthCalendarView: View {
    let monthDate: Date
    let referenceDate: Date
    let weekStart: WeekStart
    let calendar: Calendar
    let holidays: HolidayCalendar

    private var title: String {
        let formatter = DateFormatter()
        formatter.locale = calendar.locale
        let isCurrent = calendar.isDate(monthDate, equalTo: referenceDate, toGranularity: .month)
        formatter.dateFormat = isCurrent ? "MMMM yyyy" : "MMM yyyy"
        return formatter.string(from: monthDate)
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = calendar.locale
        let symbols = formatter.shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        switch weekStart {
        case .sunday:
            return symbols
        case .monday:
            return Array(symbols[1...6]) + [symbols[0]]
        }
    }

    private var days: [MonthDay] {
        MonthDay.buildGrid(for: monthDate, calendar: calendar, weekStart: weekStart)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .center)
            HStack(spacing: 2) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 8, weight: .medium))
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(days) { day in
                    Text(day.label)
                        .font(.system(size: 9, weight: day.isCurrentMonth ? .regular : .light))
                        .foregroundColor(color(for: day))
                        .frame(maxWidth: .infinity, minHeight: 12)
                }
            }
        }
    }

    private func color(for day: MonthDay) -> Color {
        guard let date = day.date else {
            return .secondary
        }
        if holidays.isHoliday(date, calendar: calendar) {
            return .red
        }
        return day.isCurrentMonth ? .primary : .secondary
    }
}

private struct MonthDay: Identifiable {
    let id = UUID()
    let label: String
    let isCurrentMonth: Bool
    let date: Date?

    static func buildGrid(for monthDate: Date, calendar: Calendar, weekStart: WeekStart) -> [MonthDay] {
        let components = calendar.dateComponents([.year, .month], from: monthDate)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay)
        else {
            return []
        }

        let weekday = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = weekdayIndex(weekday, weekStart: weekStart)
        let totalDays = range.count
        let totalCells = 42

        var cells: [MonthDay] = []
        cells.reserveCapacity(totalCells)

        for _ in 0..<leadingBlanks {
            cells.append(MonthDay(label: "", isCurrentMonth: false, date: nil))
        }

        for day in 1...totalDays {
            let dayDate = calendar.date(byAdding: .day, value: day - 1, to: firstDay)
            cells.append(MonthDay(label: String(day), isCurrentMonth: true, date: dayDate))
        }

        while cells.count < totalCells {
            cells.append(MonthDay(label: "", isCurrentMonth: false, date: nil))
        }

        return cells
    }

    private static func weekdayIndex(_ weekday: Int, weekStart: WeekStart) -> Int {
        switch weekStart {
        case .sunday:
            return max(0, weekday - 1)
        case .monday:
            return (weekday + 5) % 7
        }
    }
}
