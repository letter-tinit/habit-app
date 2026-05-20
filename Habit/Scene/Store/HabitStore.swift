//
//  HabitStore.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import Observation
import Foundation
import SwiftData

@Observable
final class HabitStore {
    // MARK: - Dependencies
    private var modelContext: ModelContext

    // MARK: - HOME PROPERTY
    var homeTitle: String = AppString.Home.today
    var habits: [Habit] = []
    var filteredHabit: [Habit] {
        return habits.filter(isHabit)
    }
    var selectedHabit: Habit?
    private(set) var selectedDate: Date = Date()

    // MARK: - PROFILE PROPERTY
    var userProfile: UserProfile?
    
    // MARK: - Constructor
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchUserProfile()
        fetchHabits()
    }
    
    // MARK: - HOME SCREEN
    func didChangeSelecteDate(_ date: Date) {
        selectedDate = date
        if selectedDate.isToday() {
            homeTitle = AppString.Home.today
        } else {
            homeTitle = selectedDate.toString(withFormat: .dayNameWithNo)
        }
    }

    func isHabit(_ habit: Habit) -> Bool {
        let date = selectedDate
        let calendar = AppCalendar.current
        let selectedDay = calendar.startOfDay(for: date)
        let createdDay = calendar.startOfDay(for: habit.createdAt)

        guard selectedDay >= createdDay, habit.archivedAt == nil else {
            return false
        }

        let weekday = calendar.component(.weekday, from: selectedDay) - 1
        let createdWeekday = calendar.component(.weekday, from: createdDay) - 1

        switch habit.frequency {
        case .daily:
            return true
        case .weekday:
            return (1...5).contains(weekday)
        case .weekend:
            return weekday == 0 || weekday == 6
        case .weekly:
            return weekday == createdWeekday
        case .custom:
            return habit.targetDaysOfWeek.contains(weekday)
        }
    }
    
    /// Input: a date param
    /// Output: check is input date is selected Date or not
    func isSelectedDay(_ date: Date) -> Bool {
        date.isEqual(with: selectedDate)
    }

    var weekStartsOnMonday: Bool {
        userProfile?.weekStartsOnMonday ?? true
    }

    var orderedWeekdays: [Int] {
        weekStartsOnMonday
            ? [1, 2, 3, 4, 5, 6, 0]
            : [0, 1, 2, 3, 4, 5, 6]
    }

    // MARK: - SWIFT DATE UTIL
    func fetchUserProfile() {
        let descriptor = FetchDescriptor<UserProfile>()

        do {
            if let existingProfile = try modelContext.fetch(descriptor).first {
                userProfile = existingProfile
                AppCalendar.weekStartsOnMonday = existingProfile.weekStartsOnMonday
            } else {
                let profile = UserProfile()
                modelContext.insert(profile)
                userProfile = profile
                AppCalendar.weekStartsOnMonday = profile.weekStartsOnMonday
                _ = save()
            }
        } catch {
            Logger.error("Failed to fetch user profile: \(error)")
            userProfile = nil
        }
    }

    func updateWeekStartsOnMonday(_ enabled: Bool) {
        if userProfile == nil {
            fetchUserProfile()
        }

        userProfile?.weekStartsOnMonday = enabled
        AppCalendar.weekStartsOnMonday = enabled
        _ = save()
    }

    func fetchHabits() {
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            habits = try modelContext.fetch(descriptor)
        } catch {
            Logger.error("Failed to fetch habits: \(error)")
            habits = []
        }
    }

    func addHabit(_ habit: Habit) {
        modelContext.insert(habit)
        if save() {
            fetchHabits()
        }
    }
    
    func habit(id: UUID) -> Habit? {
        habits.first { $0.id == id }
    }
    
    @discardableResult
    func deleteHabit(id: UUID) -> Bool {
        guard let habit = habit(id: id) else { return false }
        habits.removeAll { $0.id == id }

        modelContext.delete(habit)

        guard save() else {
            fetchHabits()
            return false
        }

        fetchHabits()
        return true
    }

    @discardableResult
    func deleteSelectedHabit() -> Bool {
        guard let habit = selectedHabit else { return false }
        let habitID = habit.id
        selectedHabit = nil
        habits.removeAll { $0.id == habitID }

        modelContext.delete(habit)

        guard save() else {
            fetchHabits()
            return false
        }

        fetchHabits()
        return true
    }

    func updateHabitEntry(_ habit: Habit, completedCount: Int, note: String? = nil) {
        let calendar = AppCalendar.current
        let targetDate = calendar.startOfDay(for: selectedDate)

        if let existingEntry = habit.entries.first(where: {
            $0.date.isEqual(with: targetDate)
        }) {
            existingEntry.completedCount = completedCount
            if let note = note {
                existingEntry.note = note
            }
            existingEntry.updatedAt = Date()
        } else {
            let newEntry = HabitEntry(date: targetDate, completedCount: completedCount, note: note ?? "")
            newEntry.habit = habit
            habit.entries.append(newEntry)
            modelContext.insert(newEntry)
        }

        updateStreaks(for: habit)
        _ = save()
    }
    
    func resetHabitEntry(_ habit: Habit) {
        let calendar = AppCalendar.current
        let targetDate = calendar.startOfDay(for: selectedDate)

        if let existingEntry = habit.entries.first(where: {
            $0.date.isEqual(with: targetDate)
        }) {
            existingEntry.completedCount = 0
            existingEntry.updatedAt = Date()
        } else {
            let newEntry = HabitEntry(date: targetDate)
            newEntry.habit = habit
            habit.entries.append(newEntry)
            modelContext.insert(newEntry)
        }

        updateStreaks(for: habit)
        _ = save()
    }

    private func updateStreaks(for habit: Habit) {
        let calendar = AppCalendar.current
        let sortedEntries = habit.entries
            .filter { $0.isCompleted }
            .sorted { $0.date > $1.date }

        guard let lastCompleted = sortedEntries.first?.date else {
            habit.currentStreak = 0
            habit.lastCompletedDate = nil
            return
        }

        habit.lastCompletedDate = lastCompleted

        var streak = 0
        var checkDate = lastCompleted

        for entry in sortedEntries {
            if entry.date.isEqual(with: checkDate) {
                streak += 1
                if let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) {
                    checkDate = previousDay
                }
            } else {
                break
            }
        }

        habit.currentStreak = streak
        habit.longestStreak = max(habit.longestStreak, streak)
    }

    private func save() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            Logger.error("Failed to save context: \(error)")
            return false
        }
    }
}
