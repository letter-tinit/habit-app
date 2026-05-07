//
//  HabitStore.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import Observation
import Foundation

@Observable
final class HabitStore {
    // MARK: - HOMESREEN
    var homeTitle: String = "TODAY"
    var habits: [Habit] = Habit.mocks
    var selectedHabit: Habit = .mock
    private(set) var selectedDate: Date = Date()
    
    
    func didChangeSelecteDate(_ date: Date) {
        selectedDate = date
    }
}
