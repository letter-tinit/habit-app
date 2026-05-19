import Foundation
import SwiftData

// MARK: - Habit (Core Entity)

@Model
final class Habit {
    var id: UUID
    var name: String
    var emoji: String
    var habitDescription: String
    var icon: String           // SF Symbol name, e.g. "drop.fill"
    var colorHex: String       // e.g. "#FF6B6B"
    var createdAt: Date
    var archivedAt: Date?      // nil = active

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

    var category: HabitCategory?

    // MARK: - Init
    init(
        name: String,
        emoji: String,
        description: String = "",
        icon: String = "star.fill",
        colorHex: String = "#4ECDC4",
        frequency: HabitFrequency = .daily,
        targetDaysOfWeek: [Int] = [],
        goalType: GoalType = .boolean,
        goalCount: Int = 1,
        goalUnit: String = "times"
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.habitDescription = description
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date()
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
    case weekly         // Same day per week
    case weekend        // Saturday and Sunday
    case custom         // N days per week/month
}

enum GoalType: String, Codable {
    case boolean        // simply completed or not
    case count          // e.g. drink 8 glasses of water
}

extension Habit {
    func entry(for date: Date) -> HabitEntry? {
        let targetDate = Calendar.current.startOfDay(for: date)
        
        return entries.first {
            $0.date.isEqual(with: targetDate)
        }
    }
}

extension Habit {
    
    static var mock: Habit {
        let habit = Habit(
            name: "Drink Water",
            emoji: "💧",
            description: "Drink enough water daily to stay hydrated",
            icon: "drop.fill",
            colorHex: "#4ECDC4",
            frequency: .daily,
            targetDaysOfWeek: [],
            goalType: .count,
            goalCount: 8,
            goalUnit: "glasses"
        )
        
        let todayEntry = HabitEntry(
            date: Date(),
            completedCount: 5,
            note: "Good hydration progress today"
        )
        todayEntry.habit = habit
        
        habit.entries = [todayEntry]
        habit.currentStreak = 3
        habit.longestStreak = 7
        habit.lastCompletedDate = Date()
        
        return habit
    }
    
    static var mocks: [Habit] {
        let calendar = Calendar.current
        let today = Date()
        
        func makeEntries(
            for habit: Habit,
            dailyCounts: [Int]
        ) -> [HabitEntry] {
            dailyCounts.enumerated().map { index, count in
                let date = calendar.date(byAdding: .day, value: -index, to: today)!
                let entry = HabitEntry(
                    date: date,
                    completedCount: count,
                    note: count > 0 ? "Progress recorded" : ""
                )
                entry.habit = habit
                return entry
            }
        }
        
        let water = Habit(
            name: "Drink Water",
            emoji: "💧",
            description: "Drink enough water daily",
            icon: "drop.fill",
            colorHex: "#4ECDC4",
            frequency: .daily,
            goalType: .count,
            goalCount: 8,
            goalUnit: "glasses"
        )
        water.entries = makeEntries(for: water, dailyCounts: [8, 7, 8, 6, 8, 6, 8])
        water.currentStreak = 3
        water.longestStreak = 10
        water.lastCompletedDate = today
        
        let reading = Habit(
            name: "Read Books",
            emoji: "📚",
            description: "Read self-development or technical books",
            icon: "book.fill",
            colorHex: "#FF6B6B",
            frequency: .daily,
            goalType: .count,
            goalCount: 90,
            goalUnit: "pages"
        )
        reading.entries = makeEntries(for: reading, dailyCounts: [30, 9, 90, 30, 20, 30, 20])
        reading.currentStreak = 2
        reading.longestStreak = 12
        reading.lastCompletedDate = today
        
        let exercise = Habit(
            name: "Exercise",
            emoji: "🏃‍♀️",
            description: "Workout or light exercise",
            icon: "figure.walk",
            colorHex: "#FFD93D",
            frequency: .weekday,
            targetDaysOfWeek: [1,2,3,4,5],
            goalType: .count,
            goalCount: 30,
            goalUnit: "minutes"
        )
        exercise.entries = makeEntries(for: exercise, dailyCounts: [20, 30, 30, 30, 0, 30, 0])
        exercise.currentStreak = 2
        exercise.longestStreak = 8
        exercise.lastCompletedDate = today
        
        let english = Habit(
            name: "Practice English",
            emoji: "🇬🇧",
            description: "Practice reading or speaking English",
            icon: "globe",
            colorHex: "#6C5CE7",
            frequency: .daily,
            goalType: .count,
            goalCount: 30,
            goalUnit: "minutes"
        )
        english.entries = makeEntries(for: english, dailyCounts: [30, 35, 30, 25, 30, 25, 30])
        english.currentStreak = 3
        english.longestStreak = 15
        english.lastCompletedDate = today
        
        let meditation = Habit(
            name: "Meditation",
            emoji: "🧘",
            description: "Mindfulness and focus practice",
            icon: "brain.head.profile",
            colorHex: "#A8E6CF",
            frequency: .weekend,
            targetDaysOfWeek: [0,6],
            goalType: .count,
            goalCount: 15,
            goalUnit: "minutes"
        )
        meditation.entries = makeEntries(for: meditation, dailyCounts: [15, 10, 15])
        meditation.currentStreak = 1
        meditation.longestStreak = 5
        meditation.lastCompletedDate = today
        
        return [
            water,
            reading,
            exercise,
            english,
            meditation
        ]
    }
}
