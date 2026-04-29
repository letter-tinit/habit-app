//
//  HabitStore.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import Observation

@Observable
final class HabitStore {
    // MARK: - HOMESREEN
    var homeTitle: String = "TODAY"
    var habits: [Habit] = Habit.mocks
    var selectedHabit: Habit = .mock
}
