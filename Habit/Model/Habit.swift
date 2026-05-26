import Foundation
import SwiftData
import SwiftUI

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
    case todo        // simply completed or not
    case count          // e.g. drink 8 glasses of water
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

extension Habit {
    var gradient: LinearGradient {
        let colors = GradientProvider.gradient(for: colorHex)

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum GradientProvider {

    static func gradient(for hex: String) -> [Color] {
        switch hex {

        case "#4ECDC4":
            return [
                Color(hex: "#8EF2EA"),
                Color(hex: "#7FE7E0")
            ]

        case "#FF6B6B":
            return [
                Color(hex: "#FFBABA"),
                Color(hex: "#FFA5A5")
            ]

        case "#FFD93D":
            return [
                Color(hex: "#FFF09A"),
                Color(hex: "#FFE985")
            ]

        case "#6C5CE7":
            return [
                Color(hex: "#C3B8FF"),
                Color(hex: "#A29BFE")
            ]

        case "#A8E6CF":
            return [
                Color(hex: "#D9FFF0"),
                Color(hex: "#C9F7E8")
            ]

        case "#87CEEB":
            return [
                Color(hex: "#CFF0FF"),
                Color(hex: "#B7E8FF")
            ]

        case "#FF66B2":
            return [
                Color(hex: "#FFC2DD"),
                Color(hex: "#FF9DCC")
            ]

        case "#FD8A5E":
            return [
                Color(hex: "#FFD0BC"),
                Color(hex: "#FFAE8B")
            ]

        case "#50C878":
            return [
                Color(hex: "#BDF4CB"),
                Color(hex: "#8BE5A8")
            ]

        case "#4169E1":
            return [
                Color(hex: "#B9CAFF"),
                Color(hex: "#8EAAFF")
            ]

        case "#E0115F":
            return [
                Color(hex: "#FFB0CE"),
                Color(hex: "#F77EAE")
            ]

        case "#8E7DBE":
            return [
                Color(hex: "#DCD1FA"),
                Color(hex: "#C2B0ED")
            ]

        case "#FF9F1C":
            return [
                Color(hex: "#FFD89B"),
                Color(hex: "#FFC065")
            ]

        case "#7AC74F":
            return [
                Color(hex: "#D2F5B6"),
                Color(hex: "#AFE487")
            ]

        default:
            return [
                Color.gray.opacity(0.4),
                Color.white
            ]
        }
    }
}
