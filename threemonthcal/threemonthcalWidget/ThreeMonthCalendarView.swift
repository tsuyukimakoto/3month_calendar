import SwiftUI
import WidgetKit

enum WeekStart {
    case sunday
    case monday
}

struct ThreeMonthCalendarView: View {
    let referenceDate: Date
    let weekStart: WeekStart
    let holidays: HolidayCalendar
    let monthNameStyle: NameStyleOption
    let weekdayNameStyle: NameStyleOption
    let widgetFamily: WidgetFamily
    let colors: WeekdayColorSet

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
            layoutBody(in: proxy.size)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: widgetFamily == .systemMedium ? .top : .center
                )
                .padding(edgeInsets(for: widgetFamily))
        }
    }

    @ViewBuilder
    private func layoutBody(in size: CGSize) -> some View {
        let months = monthDates
        switch widgetFamily {
        case .systemSmall:
            UnsupportedSizeView()
        case .systemMedium:
            layoutPresetC(months: months, size: size)
        default:
            layoutPresetD(months: months, size: size)
        }
    }

    @ViewBuilder
    private func layoutPresetC(months: [Date], size: CGSize) -> some View {
        let weekRows = weekRowCount(for: months[1])
        let topRatio: CGFloat = weekRows >= 6 ? 0.68 : (weekRows == 5 ? 0.64 : 0.60)
        let interSectionSpacing: CGFloat = 6
        let topHeight = size.height * topRatio
        let bottomHeight = max(0, size.height - topHeight - interSectionSpacing)
        let currentStyle = widgetFamily == .systemMedium
            ? styleFor(size: size, isPrimary: false)
            : styleFor(size: size, isPrimary: true)
        VStack(spacing: 0) {
            monthView(
                monthDate: months[1],
                style: currentStyle,
                maxWidth: size.width,
                maxHeight: topHeight
            )
            Spacer().frame(height: interSectionSpacing)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(alignment: .top, spacing: 4) {
                    monthView(
                        monthDate: months[0],
                        style: styleFor(size: size, isPrimary: false).compactFurther(),
                        maxWidth: size.width / 2
                    )
                    .background(monthBadge(for: months[0]))
                    SeparatorView(axis: .vertical)
                    monthView(
                        monthDate: months[2],
                        style: styleFor(size: size, isPrimary: false).compactFurther(),
                        maxWidth: size.width / 2
                    )
                    .background(monthBadge(for: months[2]))
                }
            }
            .frame(height: bottomHeight)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func weekRowCount(for monthDate: Date) -> Int {
        let components = calendar.dateComponents([.year, .month], from: monthDate)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay)
        else {
            return 5
        }
        let weekday = calendar.component(.weekday, from: firstDay)
        let leadingBlanks: Int
        switch weekStart {
        case .sunday:
            leadingBlanks = max(0, weekday - 1)
        case .monday:
            leadingBlanks = (weekday + 5) % 7
        }
        let totalCells = leadingBlanks + range.count
        return Int(ceil(Double(totalCells) / 7.0))
    }

    private func monthBadge(for monthDate: Date) -> some View {
        let month = calendar.component(.month, from: monthDate)
        return ZStack {
            Color.clear
            Text(String(month))
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(Color.primary.opacity(0.10))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func edgeInsets(for family: WidgetFamily) -> EdgeInsets {
        switch family {
        case .systemMedium:
            return EdgeInsets(top: 0, leading: 4, bottom: 4, trailing: 4)
        default:
            return EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        }
    }

    @ViewBuilder
    private func layoutPresetD(months: [Date], size: CGSize) -> some View {
        VStack(spacing: 4) {
            monthView(monthDate: months[0], style: styleFor(size: size, isPrimary: false), maxWidth: size.width)
            SeparatorView(axis: .horizontal)
            monthView(monthDate: months[1], style: styleFor(size: size, isPrimary: false), maxWidth: size.width)
            SeparatorView(axis: .horizontal)
            monthView(monthDate: months[2], style: styleFor(size: size, isPrimary: false), maxWidth: size.width)
        }
    }

    private func monthView(
        monthDate: Date,
        style: MonthViewStyle,
        maxWidth: CGFloat,
        maxHeight: CGFloat? = nil
    ) -> some View {
        let isCurrent = calendar.isDate(monthDate, equalTo: referenceDate, toGranularity: .month)
        let isLarge = widgetFamily == .systemLarge
        let emphasizeTitle = isLarge
        let effectiveStyle = (isLarge && isCurrent)
            ? style.largerForCurrent()
            : style
        return MonthCalendarView(
            monthDate: monthDate,
            referenceDate: referenceDate,
            weekStart: weekStart,
            calendar: calendar,
            holidays: holidays,
            colors: colors,
            monthNameStyle: monthNameStyle,
            weekdayNameStyle: weekdayNameStyle,
            style: effectiveStyle,
            isCurrentMonth: isCurrent,
            emphasizeTitle: emphasizeTitle,
            showTitle: isLarge
        )
        .frame(width: maxWidth, height: maxHeight)
    }

    private func styleFor(size: CGSize, isPrimary: Bool) -> MonthViewStyle {
        let narrow = size.width < 350 || size.height < 160
        if isPrimary {
            return narrow
                ? MonthViewStyle(titleSize: 9, weekdaySize: 7, daySize: 8, dayHeight: 10, headerGridSpacing: 2, gridSpacing: 2)
                : MonthViewStyle(titleSize: 10, weekdaySize: 8, daySize: 9, dayHeight: 12, headerGridSpacing: 2, gridSpacing: 2)
        } else {
            return narrow
                ? MonthViewStyle(titleSize: 8, weekdaySize: 6, daySize: 7, dayHeight: 9, headerGridSpacing: 2, gridSpacing: 2)
                : MonthViewStyle(titleSize: 9, weekdaySize: 7, daySize: 8, dayHeight: 10, headerGridSpacing: 2, gridSpacing: 2)
        }
    }

    private func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
}

private struct UnsupportedSizeView: View {
    var body: some View {
        ZStack {
            Color.clear
            Text("Small size not supported")
                .font(.system(size: 11, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(6)
        }
    }
}

private struct SeparatorView: View {
    enum Axis {
        case horizontal
        case vertical
    }

    let axis: Axis

    var body: some View {
        if axis == .horizontal {
            Rectangle()
                .fill(Color.primary.opacity(0.25))
                .frame(height: 1)
        } else {
            Rectangle()
                .fill(Color.primary.opacity(0.25))
                .frame(width: 1)
        }
    }
}

private struct MonthCalendarView: View {
    let monthDate: Date
    let referenceDate: Date
    let weekStart: WeekStart
    let calendar: Calendar
    let holidays: HolidayCalendar
    let colors: WeekdayColorSet
    let monthNameStyle: NameStyleOption
    let weekdayNameStyle: NameStyleOption
    let style: MonthViewStyle
    let isCurrentMonth: Bool
    let emphasizeTitle: Bool
    let showTitle: Bool

    private var title: String {
        let formatter = DateFormatter()
        formatter.locale = calendar.locale
        let isCurrent = calendar.isDate(monthDate, equalTo: referenceDate, toGranularity: .month)
        let monthFormat = monthNameFormat(isCurrent: isCurrent)
        formatter.dateFormat = "\(monthFormat) yyyy"
        return formatter.string(from: monthDate)
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = calendar.locale
        let symbols = weekdayNameSymbols(formatter: formatter)
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
        VStack(spacing: style.headerGridSpacing) {
            if showTitle {
                Text(title)
                    .font(.system(size: style.titleSize, weight: (isCurrentMonth && emphasizeTitle) ? .bold : .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            HStack(spacing: 2) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: style.weekdaySize, weight: .medium))
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: style.gridSpacing), count: 7),
                spacing: style.gridSpacing
            ) {
                ForEach(days) { day in
                    Text(day.label)
                        .font(.system(size: style.daySize, weight: day.isCurrentMonth ? .regular : .light))
                        .foregroundColor(color(for: day))
                        .frame(maxWidth: .infinity, minHeight: style.dayHeight)
                }
            }
        }
    }

    private func color(for day: MonthDay) -> Color {
        guard let date = day.date else {
            return .secondary
        }
        guard day.isCurrentMonth else {
            return .secondary
        }
        if holidays.isHoliday(date, calendar: calendar) {
            return colors.holiday
        }
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 1 {
            return colors.sunday
        }
        if weekday == 7 {
            return colors.saturday
        }
        return colors.weekday
    }

    private func monthNameFormat(isCurrent: Bool) -> String {
        switch monthNameStyle {
        case .full:
            return "MMMM"
        case .short:
            return "MMM"
        case .auto:
            return isCurrent ? "MMMM" : "MMM"
        }
    }

    private func weekdayNameSymbols(formatter: DateFormatter) -> [String] {
        switch weekdayNameStyle {
        case .full:
            return formatter.weekdaySymbols ?? ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        case .short:
            return formatter.shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        case .auto:
            let useFull = shouldUseFullWeekdayNames()
            return useFull
                ? (formatter.weekdaySymbols ?? ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"])
                : (formatter.shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
        }
    }

    private func shouldUseFullWeekdayNames() -> Bool {
        // Heuristic: if each column is wide enough, use full names.
        // This is intentionally simple and can be tuned after visual checks.
        let screenWidth = NSScreen.main?.frame.width ?? 800
        let estimatedColumnWidth = (screenWidth * 0.9) / 7.0
        return estimatedColumnWidth >= 42
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

struct WeekdayColorSet {
    let weekday: Color
    let sunday: Color
    let saturday: Color
    let holiday: Color
}

struct MonthViewStyle {
    let titleSize: CGFloat
    let weekdaySize: CGFloat
    let daySize: CGFloat
    let dayHeight: CGFloat
    let headerGridSpacing: CGFloat
    let gridSpacing: CGFloat

    static let standard = MonthViewStyle(
        titleSize: 10,
        weekdaySize: 8,
        daySize: 9,
        dayHeight: 12,
        headerGridSpacing: 2,
        gridSpacing: 2
    )
    static let compact = MonthViewStyle(
        titleSize: 9,
        weekdaySize: 7,
        daySize: 8,
        dayHeight: 10,
        headerGridSpacing: 2,
        gridSpacing: 2
    )
}

private extension MonthViewStyle {
    func compactFurther() -> MonthViewStyle {
        MonthViewStyle(
            titleSize: max(6, titleSize - 1),
            weekdaySize: max(5, weekdaySize - 1),
            daySize: max(6, daySize - 1),
            dayHeight: max(7, dayHeight - 2),
            headerGridSpacing: max(1, headerGridSpacing - 1),
            gridSpacing: max(1, gridSpacing - 1)
        )
    }

    func largerForCurrent() -> MonthViewStyle {
        MonthViewStyle(
            titleSize: titleSize + 3,
            weekdaySize: weekdaySize + 3,
            daySize: daySize + 3,
            dayHeight: dayHeight + 3,
            headerGridSpacing: headerGridSpacing,
            gridSpacing: gridSpacing
        )
    }
}

enum ColorResolver {
    static func resolve(_ hex: String, fallback: Color) -> Color {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        let cleaned = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        guard let value = UInt64(cleaned, radix: 16) else { return fallback }

        switch cleaned.count {
        case 6:
            let r = Double((value & 0xFF0000) >> 16) / 255.0
            let g = Double((value & 0x00FF00) >> 8) / 255.0
            let b = Double(value & 0x0000FF) / 255.0
            return Color(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
        case 8:
            let r = Double((value & 0xFF000000) >> 24) / 255.0
            let g = Double((value & 0x00FF0000) >> 16) / 255.0
            let b = Double((value & 0x0000FF00) >> 8) / 255.0
            let a = Double(value & 0x000000FF) / 255.0
            return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
        default:
            return fallback
        }
    }
}

enum ColorPresetResolver {
    static func resolve(
        preset: ColorPresetOption,
        weekdayHex: String,
        sundayHex: String,
        saturdayHex: String,
        holidayHex: String,
        colorScheme: ColorScheme
    ) -> WeekdayColorSet {
        let presetColors = presetToColors(preset, colorScheme: colorScheme)
        return WeekdayColorSet(
            weekday: ColorResolver.resolve(weekdayHex, fallback: presetColors.weekday),
            sunday: ColorResolver.resolve(sundayHex, fallback: presetColors.sunday),
            saturday: ColorResolver.resolve(saturdayHex, fallback: presetColors.saturday),
            holiday: ColorResolver.resolve(holidayHex, fallback: presetColors.holiday)
        )
    }

    private static func presetToColors(_ preset: ColorPresetOption, colorScheme: ColorScheme) -> WeekdayColorSet {
        switch preset {
        case .classic:
            let weekday = colorScheme == .dark
                ? Color(.sRGB, red: 0.90, green: 0.90, blue: 0.90, opacity: 1.0)
                : Color(.sRGB, red: 0.11, green: 0.11, blue: 0.11, opacity: 1.0)
            return WeekdayColorSet(
                weekday: weekday,
                sunday: Color(.sRGB, red: 0.84, green: 0.27, blue: 0.27, opacity: 1.0),
                saturday: Color(.sRGB, red: 0.18, green: 0.42, blue: 0.84, opacity: 1.0),
                holiday: Color(.sRGB, red: 0.84, green: 0.27, blue: 0.27, opacity: 1.0)
            )
        case .cool:
            return WeekdayColorSet(
                weekday: Color(.sRGB, red: 0.13, green: 0.17, blue: 0.23, opacity: 1.0),
                sunday: Color(.sRGB, red: 0.20, green: 0.48, blue: 0.72, opacity: 1.0),
                saturday: Color(.sRGB, red: 0.26, green: 0.64, blue: 0.58, opacity: 1.0),
                holiday: Color(.sRGB, red: 0.20, green: 0.48, blue: 0.72, opacity: 1.0)
            )
        case .warm:
            return WeekdayColorSet(
                weekday: Color(.sRGB, red: 0.20, green: 0.15, blue: 0.10, opacity: 1.0),
                sunday: Color(.sRGB, red: 0.80, green: 0.33, blue: 0.25, opacity: 1.0),
                saturday: Color(.sRGB, red: 0.72, green: 0.53, blue: 0.20, opacity: 1.0),
                holiday: Color(.sRGB, red: 0.80, green: 0.33, blue: 0.25, opacity: 1.0)
            )
        case .mono:
            return WeekdayColorSet(
                weekday: Color(.sRGB, red: 0.18, green: 0.18, blue: 0.18, opacity: 1.0),
                sunday: Color(.sRGB, red: 0.36, green: 0.36, blue: 0.36, opacity: 1.0),
                saturday: Color(.sRGB, red: 0.36, green: 0.36, blue: 0.36, opacity: 1.0),
                holiday: Color(.sRGB, red: 0.36, green: 0.36, blue: 0.36, opacity: 1.0)
            )
        }
    }
}
