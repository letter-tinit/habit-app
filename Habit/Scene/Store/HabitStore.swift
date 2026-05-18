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

    // MARK: - HOMESREEN
    var homeTitle: String = "TODAY"
    var habits: [Habit] = []
    var selectedHabit: Habit?
    private(set) var selectedDate: Date = Date()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchHabits()
    }

    func didChangeSelecteDate(_ date: Date) {
        selectedDate = date
    }

    func isHabit(_ habit: Habit, availableOn date: Date) -> Bool {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: date)
        let createdDay = calendar.startOfDay(for: habit.createdAt)

        return selectedDay >= createdDay && habit.archivedAt == nil
    }

    // MARK: - SwiftData Operations

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

    @discardableResult
    func deleteSelectedHabit() -> Bool {
        guard let habit = selectedHabit else { return false }

        modelContext.delete(habit)

        guard save() else {
            return false
        }

        selectedHabit = nil
        fetchHabits()
        return true
    }

    func updateHabitEntry(_ habit: Habit, date: Date, completedCount: Int, note: String? = nil) {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)

        if let existingEntry = habit.entries.first(where: {
            calendar.isDate($0.date, inSameDayAs: targetDate)
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

    private func updateStreaks(for habit: Habit) {
        let calendar = Calendar.current
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
            if calendar.isDate(entry.date, inSameDayAs: checkDate) {
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
