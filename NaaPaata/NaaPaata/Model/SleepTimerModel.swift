//
//  SleepTimerModel.swift
//  NaaPaata
//
//  Created by Antigravity on 2/16/26.
//

import Foundation
import SwiftData

@Model
final class SleepTimerModel {
    var hours: Int
    var minutes: Int
    var isEnabled: Bool
    var targetDate: Date?
    
    init(hours: Int = 0, minutes: Int = 0, isEnabled: Bool = false, targetDate: Date? = nil) {
        self.hours = hours
        self.minutes = minutes
        self.isEnabled = isEnabled
        self.targetDate = targetDate
    }
}
