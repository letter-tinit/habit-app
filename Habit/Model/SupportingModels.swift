import Foundation
import SwiftData

// MARK: - HabitCategory

@Model
final class HabitCategory {
    var id: UUID
    var name: String          // e.g. "Health", "Learning", "Fitness"
    var icon: String          // SF Symbol
    var colorHex: String
    var sortOrder: Int

    @Relationship(inverse: \Habit.category)
    var habits: [Habit]

    init(name: String, icon: String = "folder.fill", colorHex: String = "#888888", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.habits = []
    }
}

// MARK: - HabitReminder
// Supports multiple custom reminder times per habit.

@Model
final class HabitReminder {
    var id: UUID
    var time: Date            // Only time component is used
    var daysOfWeek: [Int]     // Empty = every scheduled day
    var isEnabled: Bool
    var notificationID: String  // Maps to UNNotificationRequest identifier

    var habit: Habit?

    init(time: Date, daysOfWeek: [Int] = [], isEnabled: Bool = true) {
        self.id = UUID()
        self.time = time
        self.daysOfWeek = daysOfWeek
        self.isEnabled = isEnabled
        self.notificationID = UUID().uuidString
    }
}

// MARK: - UserProfile
// Singleton-style; stores app-wide settings and aggregated stats.

@Model
final class UserProfile {
    var id: UUID
    var displayName: String
    var avatarData: Data?      // Stored as PNG/JPEG data

    // App preferences
    var weekStartsOnMonday: Bool
    var defaultReminderTime: Date?
    var themeColorHex: String

    // Aggregated lifetime stats (updated on each completion)
    var totalCompletions: Int
    var totalHabitsCreated: Int
    var longestOverallStreak: Int
    var joinedAt: Date

    init(displayName: String = "You") {
        self.id = UUID()
        self.displayName = displayName
        self.weekStartsOnMonday = true
        self.themeColorHex = "#4ECDC4"
        self.totalCompletions = 0
        self.totalHabitsCreated = 0
        self.longestOverallStreak = 0
        self.joinedAt = Date()
    }
}
