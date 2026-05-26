//
//  Date+Extension.swift
//  Habit
//
//  Created by TiniT on 29/4/26.
//

import Foundation

enum DateFormat {
    case dayNameSymbol // T (Tuesday)
    case dayName // Tu (Tuesday)
    case dayNo // 26 (Number of day only)
    case dayNameWithNo // Tue, 26 (combine of day number and day name)
    case custom(String) // Passing date format throught string
    
    var value: String {
        switch self {
        case .dayNameSymbol:
            "EEEEE"
        case .dayName:
            "EEEEEE"
        case .dayNo:
            "d"
        case .dayNameWithNo:
            "EEE, d"
        case .custom(let value):
            value
        }
    }
}

extension Date {
    func isToday() -> Bool {
        return AppCalendar.current.isDateInToday(self)
    }
    
    func toString(withFormat dateFormat: DateFormat) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat.value
        return formatter.string(from: self)
    }
    
    func isEqual(with targetDate: Date) -> Bool {
        AppCalendar.current.isDate(self, inSameDayAs: targetDate)
    }

    func isFutureDay() -> Bool {
        AppCalendar.current.startOfDay(for: self) > AppCalendar.current.startOfDay(for: Date())
    }
}
