//
//  Date+Extension.swift
//  Habit
//
//  Created by TiniT on 29/4/26.
//

import Foundation

extension Date {
    func isToday() -> Bool {
        return Calendar.current.isDateInToday(self)
    }
}
