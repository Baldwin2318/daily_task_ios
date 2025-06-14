//
//  DailyTaskWidgetBundle.swift
//  DailyTaskWidget
//
//  Created by Baldwin Kiel Malabanan on 2025-06-14.
//

import WidgetKit
import SwiftUI

@main
struct DailyTaskWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyTaskWidget()
        DailyTaskWidgetControl()
        DailyTaskWidgetLiveActivity()
    }
}
