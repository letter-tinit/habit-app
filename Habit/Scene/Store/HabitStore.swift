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
        shouldSchedule(habit, on: selectedDate, calendar: AppCalendar.current)
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
        let completedDates = Set(
            habit.entries
                .filter { $0.isCompleted }
                .map { calendar.startOfDay(for: $0.date) }
                .filter { shouldSchedule(habit, on: $0, calendar: calendar) }
        )

        guard let lastCompleted = completedDates.max() else {
            habit.currentStreak = 0
            habit.lastCompletedDate = nil
            return
        }

        habit.lastCompletedDate = lastCompleted
        habit.currentStreak = streakEnding(
            at: lastCompleted,
            completedDates: completedDates,
            habit: habit,
            calendar: calendar
        )
        habit.longestStreak = longestStreak(
            completedDates: completedDates,
            habit: habit,
            calendar: calendar
        )
    }

    private func longestStreak(
        completedDates: Set<Date>,
        habit: Habit,
        calendar: Calendar
    ) -> Int {
        let sortedCompletedDates = completedDates.sorted()
        var longestStreak = 0

        for date in sortedCompletedDates {
            guard shouldSchedule(habit, on: date, calendar: calendar) else {
                continue
            }

            longestStreak = max(
                longestStreak,
                streakEnding(
                    at: date,
                    completedDates: completedDates,
                    habit: habit,
                    calendar: calendar
                )
            )
        }

        return longestStreak
    }

    private func streakEnding(
        at date: Date,
        completedDates: Set<Date>,
        habit: Habit,
        calendar: Calendar
    ) -> Int {
        var streak = 0
        var checkDate = calendar.startOfDay(for: date)

        while completedDates.contains(checkDate) {
            streak += 1

            guard let previousDate = previousScheduledDate(
                before: checkDate,
                habit: habit,
                calendar: calendar
            ) else {
                break
            }

            checkDate = previousDate
        }

        return streak
    }

    private func previousScheduledDate(
        before date: Date,
        habit: Habit,
        calendar: Calendar
    ) -> Date? {
        var date = calendar.startOfDay(for: date)
        let createdDay = calendar.startOfDay(for: habit.createdAt)

        repeat {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else {
                return nil
            }

            date = previousDay

            if date < createdDay {
                return nil
            }
        } while !shouldSchedule(habit, on: date, calendar: calendar)

        return date
    }

    private func shouldSchedule(
        _ habit: Habit,
        on date: Date,
        calendar: Calendar
    ) -> Bool {
        let day = calendar.startOfDay(for: date)
        let createdDay = calendar.startOfDay(for: habit.createdAt)

        guard day >= createdDay, habit.archivedAt == nil else {
            return false
        }

        let weekday = calendar.component(.weekday, from: day) - 1

        switch habit.frequency {
        case .daily:
            return true
        case .weekday:
            return (1...5).contains(weekday)
        case .weekend:
            return weekday == 0 || weekday == 6
        case .custom:
            return habit.targetDaysOfWeek.contains(weekday)
        }
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
    
    // MARK: - STATISTICS
    func monthDates(containing date: Date) -> [Date] {
        let calendar = AppCalendar.current
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }
        
        var dates: [Date] = []
        var currentDate = calendar.startOfDay(for: monthInterval.start)
        
        while currentDate < monthInterval.end {
            dates.append(currentDate)
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            
            currentDate = nextDate
        }
        
        return dates
    }

    func completionRatio(on date: Date) -> Double {
        let calendar = AppCalendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        let scheduledHabits = habits.filter {
            shouldSchedule($0, on: targetDate, calendar: calendar)
        }
        
        guard !scheduledHabits.isEmpty else {
            return 0
        }
        
        let totalRatio = scheduledHabits.reduce(0.0) { result, habit in
            let entry = habit.entries.first {
                calendar.isDate($0.date, inSameDayAs: targetDate)
            }
            
            guard habit.goalCount > 0 else {
                return result
            }
            
            let completedCount = entry?.completedCount ?? 0
            let ratio = min(Double(completedCount) / Double(habit.goalCount), 1.0)
            
            return result + ratio
        }
        
        return totalRatio / Double(scheduledHabits.count)
    }

    func completionRatioForMonth(containing date: Date) -> Double {
        let dates = monthDates(containing: date)
        return completionRatio(for: dates)
    }

    func completionRatioForYear(containing date: Date) -> Double {
        let calendar = AppCalendar.current
        
        guard let yearInterval = calendar.dateInterval(of: .year, for: date) else {
            return 0
        }
        
        var dates: [Date] = []
        var currentDate = calendar.startOfDay(for: yearInterval.start)
        
        while currentDate < yearInterval.end {
            dates.append(currentDate)
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            
            currentDate = nextDate
        }
        
        return completionRatio(for: dates)
    }

    private func completionRatio(for dates: [Date]) -> Double {
        let validDates = dates.filter { date in
            habits.contains {
                shouldSchedule($0, on: date, calendar: AppCalendar.current)
            }
        }
        
        guard !validDates.isEmpty else {
            return 0
        }
        
        let totalRatio = validDates.reduce(0.0) { result, date in
            result + completionRatio(on: date)
        }
        
        return totalRatio / Double(validDates.count)
    }
}
