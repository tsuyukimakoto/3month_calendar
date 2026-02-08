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
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), holidays: HolidayCalendar(dates: []))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, holidays: HolidayCalendar(dates: []))
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let now = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: now)
        let years = [currentYear, currentYear + 1]
        let store = HolidayStore.shared
        var holidays = store.loadCachedHolidays(years: years, calendar: calendar)

        if store.shouldRefresh(referenceDate: now, calendar: calendar) {
            if let fetched = await store.fetchAndCache(
                years: years,
                calendar: calendar,
                overrideURL: configuration.holidaySourceUrl
            ) {
                holidays = fetched
                store.markRefreshed(referenceDate: now, calendar: calendar)
                WidgetCenter.shared.reloadTimelines(ofKind: "threemonthcalWidget")
            }
        }

        let entry = SimpleEntry(date: now, configuration: configuration, holidays: holidays)
        let nextMidnight = calendar.nextDate(
            after: entry.date,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        )
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
}

struct threemonthcalWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ThreeMonthCalendarView(
            referenceDate: entry.date,
            weekStart: entry.configuration.weekStart.weekStart,
            holidays: entry.holidays,
            colors: ColorPresetResolver.resolve(
                preset: entry.configuration.colorPreset,
                weekdayHex: entry.configuration.weekdayColorHex,
                sundayHex: entry.configuration.sundayColorHex,
                saturdayHex: entry.configuration.saturdayColorHex,
                holidayHex: entry.configuration.holidayColorHex
            )
        )
    }
}

struct threemonthcalWidget: Widget {
    let kind: String = "threemonthcalWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            threemonthcalWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}
