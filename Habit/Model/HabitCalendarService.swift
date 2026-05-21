import Foundation
import SwiftData

// MARK: - ModelContainer Configuration

extension ModelContainer {
    static var habitTracker: ModelContainer = {
        let schema = Schema([
            Habit.self,
            HabitEntry.self,
            HabitReminder.self,
            UserProfile.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        return try! ModelContainer(for: schema, configurations: config)
    }()
}

// MARK: - Calendar Query Helpers

struct HabitCalendarService {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // ── Fetch all entries for a specific calendar month ──────────────────
    func entries(for habit: Habit, in month: Date) -> [HabitEntry] {
        let cal = AppCalendar.current
        guard
            let start = cal.date(from: cal.dateComponents([.year, .month], from: month)),
            let end   = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start)
        else { return [] }

        let habitID = habit.persistentModelID

        let predicate = #Predicate<HabitEntry> { entry in
            entry.habit?.persistentModelID == habitID &&
            entry.date >= start &&
            entry.date <= end
        }

        let descriptor = FetchDescriptor<HabitEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    // ── Fetch all habits that should appear on a given date ───────────────
//    func scheduledHabits(for date: Date) -> [Habit] {
//        let weekday = AppCalendar.current.component(.weekday, from: date) - 1 // 0-indexed
//
//        let predicate = #Predicate<Habit> { habit in
//            habit.archivedAt == nil && (
//                habit.frequency == .daily ||
//                habit.targetDaysOfWeek.contains(weekday)
//            )
//        }
//
//        let descriptor = FetchDescriptor<Habit>(predicate: predicate)
//        return (try? context.fetch(descriptor)) ?? []
//    }

    // ── Completion map for a full month: [dayNumber: Bool] ───────────────
    func completionMap(for habit: Habit, in month: Date) -> [Int: Bool] {
        let cal = AppCalendar.current
        return Dictionary(
            uniqueKeysWithValues: entries(for: habit, in: month).compactMap { entry in
                let day = cal.component(.day, from: entry.date)
                return (day, entry.isCompleted)
            }
        )
    }

    // ── Weekly completion rate (last 7 days) ─────────────────────────────
    func weeklyRate(for habit: Habit) -> Double {
        let today = AppCalendar.current.startOfDay(for: Date())
        guard let weekAgo = AppCalendar.current.date(byAdding: .day, value: -6, to: today) else { return 0 }

        let habitID = habit.persistentModelID
        let predicate = #Predicate<HabitEntry> { entry in
            entry.habit?.persistentModelID == habitID &&
            entry.date >= weekAgo &&
            entry.date <= today
        }
        let descriptor = FetchDescriptor<HabitEntry>(predicate: predicate)
        let entries = (try? context.fetch(descriptor)) ?? []
        let completed = entries.filter { $0.isCompleted }.count
        return Double(completed) / 7.0
    }

    // ── Upsert a HabitEntry for today ────────────────────────────────────
    @discardableResult
    func logCompletion(for habit: Habit, count: Int = 1, note: String = "") -> HabitEntry {
        let today = AppCalendar.current.startOfDay(for: Date())
        let habitID = habit.persistentModelID

        let predicate = #Predicate<HabitEntry> { entry in
            entry.habit?.persistentModelID == habitID && entry.date == today
        }
        let descriptor = FetchDescriptor<HabitEntry>(predicate: predicate)

        if let existing = try? context.fetch(descriptor).first {
            existing.completedCount = count
            existing.note = note
            existing.updatedAt = Date()
            return existing
        } else {
            let entry = HabitEntry(date: today, completedCount: count, note: note)
            entry.habit = habit
            context.insert(entry)
            return entry
        }
    }

    // ── Streak recalculation ─────────────────────────────────────────────
    func recalculateStreak(for habit: Habit) {
        let habitID = habit.persistentModelID
        let predicate = #Predicate<HabitEntry> { entry in
            entry.habit?.persistentModelID == habitID
        }
        let descriptor = FetchDescriptor<HabitEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let allEntries = (try? context.fetch(descriptor)) ?? []
        let completedDates = Set(
            allEntries.filter { $0.isCompleted }
                      .map { AppCalendar.current.startOfDay(for: $0.date) }
        )

        var streak = 0
        var checking = AppCalendar.current.startOfDay(for: Date())

        while completedDates.contains(checking) {
            streak += 1
            checking = AppCalendar.current.date(byAdding: .day, value: -1, to: checking)!
        }

        habit.currentStreak = streak
        if streak > habit.longestStreak { habit.longestStreak = streak }
        habit.lastCompletedDate = completedDates.max()
    }
}
