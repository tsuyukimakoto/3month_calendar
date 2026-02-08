//
//  AppIntent.swift
//  threemonthcalWidget
//
//  Created by Makoto Tsuyuki on 2026/02/08.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Calendar Settings" }
    static var description: IntentDescription { "Configure the calendar display." }

    @Parameter(title: "Week Starts On", default: .sunday)
    var weekStart: WeekStartOption

    @Parameter(title: "Holiday Calendar URL", default: "")
    var holidaySourceUrl: String
}

enum WeekStartOption: String, AppEnum {
    case sunday
    case monday

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Week Start"
    }

    static var caseDisplayRepresentations: [WeekStartOption: DisplayRepresentation] {
        [
            .sunday: "Sunday",
            .monday: "Monday"
        ]
    }
}
