import Foundation
import SwiftData

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
    var avatarOriginalData: Data?   // Source image used for future edits
    var avatarData: Data?           // Cropped/rendered image used for display

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
