//
//  threemonthcalWidget.swift
//  threemonthcalWidget
//
//  Created by Makoto Tsuyuki on 2026/02/08.
//

import WidgetKit
import SwiftUI

private extension WeekStartOption {
    var weekStart: WeekStart {
        switch self {
        case .sunday:
            return .sunday
        case .monday:
            return .monday
        }
    }
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            holidays: HolidayCalendar(dates: []),
            errorMessage: nil
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: configuration,
            holidays: HolidayCalendar(dates: []),
            errorMessage: nil
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let now = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: now)
        let years = [currentYear, currentYear + 1]
        let store = HolidayStore.shared
        var holidays = store.loadCachedHolidays(years: years, calendar: calendar)
        var errorMessage: String? = nil

        let missingCache = years.contains { !store.hasCache(for: $0) }
        if missingCache || store.shouldRefresh(referenceDate: now, calendar: calendar) {
            if let fetched = await store.fetchAndCache(
                years: years,
                calendar: calendar,
                overrideURL: configuration.holidaySourceUrl ?? ""
            ) {
                holidays = fetched
                store.markRefreshed(referenceDate: now, calendar: calendar)
                WidgetCenter.shared.reloadTimelines(ofKind: "threemonthcalWidget")
            } else {
                errorMessage = "Holiday fetch failed"
            }
        }

        let entry = SimpleEntry(
            date: now,
            configuration: configuration,
            holidays: holidays,
            errorMessage: errorMessage
        )
        let nextMidnight = calendar.nextDate(
            after: entry.date,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        )
        if errorMessage != nil {
            let clearEntry = SimpleEntry(
                date: now.addingTimeInterval(5),
                configuration: configuration,
                holidays: holidays,
                errorMessage: nil
            )
            return Timeline(entries: [entry, clearEntry], policy: .after(nextMidnight ?? entry.date.addingTimeInterval(60 * 60)))
        }
        return Timeline(entries: [entry], policy: .after(nextMidnight ?? entry.date.addingTimeInterval(60 * 60)))
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let holidays: HolidayCalendar
    let errorMessage: String?
}

struct threemonthcalWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        let config = entry.configuration
        if let message = entry.errorMessage {
            ErrorOverlayView(message: message)
                .widgetURL(actionURL(for: config.onClickAction ?? .doNothing))
        } else {
            ThreeMonthCalendarView(
                referenceDate: entry.date,
                weekStart: (config.weekStart ?? .sunday).weekStart,
                holidays: entry.holidays,
                monthNameStyle: config.monthNameStyle ?? .auto,
                weekdayNameStyle: config.weekdayNameStyle ?? .auto,
                widgetFamily: widgetFamily,
                colors: ColorPresetResolver.resolve(
                    preset: config.colorPreset ?? .classic,
                    weekdayHex: config.weekdayColorHex ?? "",
                    sundayHex: config.sundayColorHex ?? "",
                    saturdayHex: config.saturdayColorHex ?? "",
                    holidayHex: config.holidayColorHex ?? "",
                    colorScheme: colorScheme
                )
            )
            .widgetURL(actionURL(for: config.onClickAction ?? .doNothing))
        }
    }

    private func actionURL(for action: OnClickActionOption) -> URL? {
        switch action {
        case .doNothing:
            return nil
        case .calendarApp:
            // Commonly used to open Calendar.app on macOS (not officially documented).
            return URL(string: "ical://")
        case .googleCalendar:
            return URL(string: "https://calendar.google.com/calendar/ical/2bk907eqjut8imoorgq1qa4olc%40group.calendar.google.com/public/basic.ics")
        }
    }
}

private struct ErrorOverlayView: View {
    let message: String

    var body: some View {
        ZStack {
            Color.clear
            Text(message)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(6)
        }
    }
}

struct threemonthcalWidget: Widget {
    let kind: String = "threemonthcalWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            if #available(macOS 14.0, *) {
                threemonthcalWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                threemonthcalWidgetEntryView(entry: entry)
            }
        }
    }
}
