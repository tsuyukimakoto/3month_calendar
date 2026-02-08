//
//  threemonthcalWidgetBundle.swift
//  threemonthcalWidget
//
//  Created by Makoto Tsuyuki on 2026/02/08.
//

import WidgetKit
import SwiftUI

@main
struct threemonthcalWidgetBundle: WidgetBundle {
    var body: some Widget {
        threemonthcalWidget()
        if #available(macOS 26.0, *) {
            threemonthcalWidgetControl()
        }
    }
}
