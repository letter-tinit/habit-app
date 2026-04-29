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
    static var mock: Habit {
        Habit(
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
    }
    
    static var mocks: [Habit] {
        [
            Habit(
                name: "Drink Water",
                emoji: "💧",
                description: "Drink enough water daily",
                icon: "drop.fill",
                colorHex: "#4ECDC4",
                frequency: .daily,
                goalType: .count,
                goalCount: 8,
                goalUnit: "glasses"
            ),
            
            Habit(
                name: "Read Books",
                emoji: "📚",
                description: "Read self-development or technical books",
                icon: "book.fill",
                colorHex: "#FF6B6B",
                frequency: .daily,
                goalType: .count,
                goalCount: 30,
                goalUnit: "pages"
            ),
            
            Habit(
                name: "Exercise",
                emoji: "🏃‍♀️",
                description: "Workout or light exercise",
                icon: "figure.walk",
                colorHex: "#FFD93D",
                frequency: .weekday,
                goalType: .count,
                goalCount: 30,
                goalUnit: "minutes"
            ),
            
            Habit(
                name: "Practice English",
                emoji: "🏋️",
                description: "Practice reading or speaking English",
                icon: "globe",
                colorHex: "#6C5CE7",
                frequency: .daily,
                goalType: .count,
                goalCount: 30,
                goalUnit: "minutes"
            ),
            
            Habit(
                name: "Meditation",
                emoji: "🧘",
                description: "Mindfulness and focus practice",
                icon: "brain.head.profile",
                colorHex: "#A8E6CF",
                frequency: .weekend,
                goalType: .count,
                goalCount: 15,
                goalUnit: "minutes"
            )
        ]
    }
}
