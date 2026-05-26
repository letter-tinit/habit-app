import Foundation
import SwiftData

// MARK: - Habit (Core Entity)

@Model
final class Habit: Hashable {
    var id: UUID
    var name: String
    var habitDescription: String
    var icon: String           // SF Symbol name, e.g. "drop.fill"
    var colorHex: String       // e.g. "#FF6B6B"
    var createdAt: Date
    var archivedAt: Date?      // nil = active
    var sortOrder: Int = 0

    // Scheduling
    var frequency: HabitFrequency          // daily / weekly / custom
    var targetDaysOfWeek: [Int]            // 0=Sun … 6=Sat (used when frequency == .weekly/.custom)
    var reminderTime: Date?                // optional daily reminder

    // Goal
    var goalType: GoalType                 // boolean (done/not done) or count-based
    var goalCount: Int                     // target count per period (1 for boolean habits)
    var goalUnit: String                   // e.g. "glasses", "pages", "minutes"

    // Streaks (denormalised for fast reads)
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDate: Date?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry]

    @Relationship(deleteRule: .cascade, inverse: \HabitReminder.habit)
    var reminders: [HabitReminder]

    // MARK: - Init
    init(
        name: String,
        description: String = "",
        icon: String = "star.fill",
        colorHex: String = "#4ECDC4",
        frequency: HabitFrequency = .daily,
        targetDaysOfWeek: [Int] = [],
        goalType: GoalType = .todo,
        goalCount: Int = 1,
        goalUnit: String = "times"
    ) {
        self.id = UUID()
        self.name = name
        self.habitDescription = description
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date()
        self.sortOrder = Int(Date().timeIntervalSince1970)
        self.frequency = frequency
        self.targetDaysOfWeek = targetDaysOfWeek
        self.goalType = goalType
        self.goalCount = goalCount
        self.goalUnit = goalUnit
        self.currentStreak = 0
        self.longestStreak = 0
        self.entries = []
        self.reminders = []
    }
}

// MARK: - Enums

enum HabitFrequency: String, Codable {
    case daily
    case weekday      // Monday to Friday
    case weekend        // Saturday and Sunday
    case custom         // N days per week/month
}

enum GoalType: String, Codable {
    case count          // e.g. drink 8 glasses of water
    case todo        // simply completed or not
}

extension Habit {
    var isArchived: Bool {
        archivedAt != nil
    }

    func entry(for date: Date) -> HabitEntry? {
        let targetDate = AppCalendar.current.startOfDay(for: date)

        return entries.first {
            $0.date.isEqual(with: targetDate)
        }
    }
}
