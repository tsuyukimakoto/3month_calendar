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

    @Parameter(title: "Color Preset", default: .classic)
    var colorPreset: ColorPresetOption

    @Parameter(title: "Custom Weekday Color (Mon-Fri)", default: "")
    var weekdayColorHex: String

    @Parameter(title: "Custom Sunday Color", default: "")
    var sundayColorHex: String

    @Parameter(title: "Custom Saturday Color", default: "")
    var saturdayColorHex: String

    @Parameter(title: "Custom Holiday Color", default: "")
    var holidayColorHex: String
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
