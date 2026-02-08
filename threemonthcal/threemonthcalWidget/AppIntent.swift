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
    var weekStart: WeekStartOption?

    @Parameter(title: "Holiday Calendar URL", default: "")
    var holidaySourceUrl: String?

    @Parameter(title: "On Click Action", default: .doNothing)
    var onClickAction: OnClickActionOption?

    @Parameter(title: "Month Name Style", default: .auto)
    var monthNameStyle: NameStyleOption?

    @Parameter(title: "Weekday Name Style", default: .auto)
    var weekdayNameStyle: NameStyleOption?

    @Parameter(title: "Color Preset", default: .classic)
    var colorPreset: ColorPresetOption?

    @Parameter(title: "Custom Weekday Color (Mon-Fri)", default: "")
    var weekdayColorHex: String?

    @Parameter(title: "Custom Sunday Color", default: "")
    var sundayColorHex: String?

    @Parameter(title: "Custom Saturday Color", default: "")
    var saturdayColorHex: String?

    @Parameter(title: "Custom Holiday Color", default: "")
    var holidayColorHex: String?
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

enum ColorPresetOption: String, AppEnum {
    case classic
    case cool
    case warm
    case mono

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Color Preset"
    }

    static var caseDisplayRepresentations: [ColorPresetOption: DisplayRepresentation] {
        [
            .classic: "Classic",
            .cool: "Cool",
            .warm: "Warm",
            .mono: "Mono"
        ]
    }
}

enum OnClickActionOption: String, AppEnum {
    case doNothing
    case calendarApp
    case googleCalendar

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "On Click Action"
    }

    static var caseDisplayRepresentations: [OnClickActionOption: DisplayRepresentation] {
        [
            .doNothing: "Do Nothing",
            .calendarApp: "Open Calendar App",
            .googleCalendar: "Open Google Calendar"
        ]
    }
}

enum NameStyleOption: String, AppEnum {
    case auto
    case full
    case short

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Name Style"
    }

    static var caseDisplayRepresentations: [NameStyleOption: DisplayRepresentation] {
        [
            .auto: "Auto",
            .full: "Full",
            .short: "Short"
        ]
    }
}
