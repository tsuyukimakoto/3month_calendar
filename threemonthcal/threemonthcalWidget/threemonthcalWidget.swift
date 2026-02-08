//
//  threemonthcalWidget.swift
//  threemonthcalWidget
//
//  Created by Makoto Tsuyuki on 2026/02/08.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        let calendar = Calendar.current
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
}

struct threemonthcalWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ThreeMonthCalendarView(referenceDate: entry.date, weekStart: .sunday)
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
