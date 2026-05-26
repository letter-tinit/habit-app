import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct HabitBackup: Codable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var exportedAt: Date
    var profile: UserProfileBackup?
    var habits: [HabitBackupItem]

    init(profile: UserProfile?, habits: [Habit]) {
        self.schemaVersion = Self.currentSchemaVersion
        self.exportedAt = Date()
        self.profile = profile.map(UserProfileBackup.init)
        self.habits = habits.map(HabitBackupItem.init)
    }
}

struct HabitBackupSummary {
    let exportedAt: Date
    let habitCount: Int
    let entryCount: Int
    let reminderCount: Int
    let profileName: String
}

extension HabitBackup {
    var summary: HabitBackupSummary {
        HabitBackupSummary(
            exportedAt: exportedAt,
            habitCount: habits.count,
            entryCount: habits.reduce(0) { $0 + $1.entries.count },
            reminderCount: habits.reduce(0) { $0 + $1.reminders.count },
            profileName: profile?.displayName ?? "You"
        )
    }

    func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw HabitBackupError.unsupportedSchemaVersion(schemaVersion)
        }

        let habitIDs = habits.map(\.id)
        guard Set(habitIDs).count == habitIDs.count else {
            throw HabitBackupError.invalidData("The backup contains duplicate habit IDs.")
        }

        for habit in habits {
            try habit.validate()
        }
    }
}

extension HabitBackupItem {
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw HabitBackupError.invalidData("The backup contains a habit with an empty name.")
        }

        guard goalCount > 0 else {
            throw HabitBackupError.invalidData("The habit \"\(name)\" has an invalid goal count.")
        }

        guard targetDaysOfWeek.allSatisfy({ (0...6).contains($0) }) else {
            throw HabitBackupError.invalidData("The habit \"\(name)\" has invalid scheduled days.")
        }

        let entryIDs = entries.map(\.id)
        guard Set(entryIDs).count == entryIDs.count else {
            throw HabitBackupError.invalidData("The habit \"\(name)\" contains duplicate entry IDs.")
        }

        let reminderIDs = reminders.map(\.id)
        guard Set(reminderIDs).count == reminderIDs.count else {
            throw HabitBackupError.invalidData("The habit \"\(name)\" contains duplicate reminder IDs.")
        }

        for entry in entries {
            try entry.validate(habitName: name)
        }

        for reminder in reminders {
            try reminder.validate(habitName: name)
        }
    }
}

extension HabitEntryBackupItem {
    func validate(habitName: String) throws {
        guard completedCount >= 0 else {
            throw HabitBackupError.invalidData("The habit \"\(habitName)\" contains an entry with a negative completion count.")
        }
    }
}

extension HabitReminderBackupItem {
    func validate(habitName: String) throws {
        guard daysOfWeek.allSatisfy({ (0...6).contains($0) }) else {
            throw HabitBackupError.invalidData("The habit \"\(habitName)\" contains a reminder with invalid days.")
        }

        guard !notificationID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw HabitBackupError.invalidData("The habit \"\(habitName)\" contains a reminder with an empty notification ID.")
        }
    }
}

struct UserProfileBackup: Codable {
    var id: UUID
    var displayName: String
    var avatarOriginalData: Data?
    var avatarData: Data?
    var weekStartsOnMonday: Bool
    var usesSimplifiedStatisticsMode: Bool
    var defaultReminderTime: Date?
    var themeColorHex: String
    var totalCompletions: Int
    var totalHabitsCreated: Int
    var longestOverallStreak: Int
    var joinedAt: Date

    init(_ profile: UserProfile) {
        id = profile.id
        displayName = profile.displayName
        avatarOriginalData = profile.avatarOriginalData
        avatarData = profile.avatarData
        weekStartsOnMonday = profile.weekStartsOnMonday
        usesSimplifiedStatisticsMode = profile.usesSimplifiedStatisticsMode
        defaultReminderTime = profile.defaultReminderTime
        themeColorHex = profile.themeColorHex
        totalCompletions = profile.totalCompletions
        totalHabitsCreated = profile.totalHabitsCreated
        longestOverallStreak = profile.longestOverallStreak
        joinedAt = profile.joinedAt
    }
}

struct HabitBackupItem: Codable {
    var id: UUID
    var name: String
    var habitDescription: String
    var icon: String
    var colorHex: String
    var createdAt: Date
    var archivedAt: Date?
    var sortOrder: Int
    var frequency: HabitFrequency
    var targetDaysOfWeek: [Int]
    var reminderTime: Date?
    var goalType: GoalType
    var goalCount: Int
    var goalUnit: String
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDate: Date?
    var entries: [HabitEntryBackupItem]
    var reminders: [HabitReminderBackupItem]

    init(_ habit: Habit) {
        id = habit.id
        name = habit.name
        habitDescription = habit.habitDescription
        icon = habit.icon
        colorHex = habit.colorHex
        createdAt = habit.createdAt
        archivedAt = habit.archivedAt
        sortOrder = habit.sortOrder
        frequency = habit.frequency
        targetDaysOfWeek = habit.targetDaysOfWeek
        reminderTime = habit.reminderTime
        goalType = habit.goalType
        goalCount = habit.goalCount
        goalUnit = habit.goalUnit
        currentStreak = habit.currentStreak
        longestStreak = habit.longestStreak
        lastCompletedDate = habit.lastCompletedDate
        entries = habit.entries.map(HabitEntryBackupItem.init)
        reminders = habit.reminders.map(HabitReminderBackupItem.init)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case habitDescription
        case icon
        case colorHex
        case createdAt
        case archivedAt
        case sortOrder
        case frequency
        case targetDaysOfWeek
        case reminderTime
        case goalType
        case goalCount
        case goalUnit
        case currentStreak
        case longestStreak
        case lastCompletedDate
        case entries
        case reminders
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        habitDescription = try container.decode(String.self, forKey: .habitDescription)
        icon = try container.decode(String.self, forKey: .icon)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        archivedAt = try container.decodeIfPresent(Date.self, forKey: .archivedAt)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        frequency = try container.decode(HabitFrequency.self, forKey: .frequency)
        targetDaysOfWeek = try container.decode([Int].self, forKey: .targetDaysOfWeek)
        reminderTime = try container.decodeIfPresent(Date.self, forKey: .reminderTime)
        goalType = try container.decode(GoalType.self, forKey: .goalType)
        goalCount = try container.decode(Int.self, forKey: .goalCount)
        goalUnit = try container.decode(String.self, forKey: .goalUnit)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        longestStreak = try container.decode(Int.self, forKey: .longestStreak)
        lastCompletedDate = try container.decodeIfPresent(Date.self, forKey: .lastCompletedDate)
        entries = try container.decode([HabitEntryBackupItem].self, forKey: .entries)
        reminders = try container.decode([HabitReminderBackupItem].self, forKey: .reminders)
    }
}

struct HabitEntryBackupItem: Codable {
    var id: UUID
    var date: Date
    var completedCount: Int
    var note: String
    var mood: MoodRating?
    var createdAt: Date
    var updatedAt: Date

    init(_ entry: HabitEntry) {
        id = entry.id
        date = entry.date
        completedCount = entry.completedCount
        note = entry.note
        mood = entry.mood
        createdAt = entry.createdAt
        updatedAt = entry.updatedAt
    }
}

struct HabitReminderBackupItem: Codable {
    var id: UUID
    var time: Date
    var daysOfWeek: [Int]
    var isEnabled: Bool
    var notificationID: String

    init(_ reminder: HabitReminder) {
        id = reminder.id
        time = reminder.time
        daysOfWeek = reminder.daysOfWeek
        isEnabled = reminder.isEnabled
        notificationID = reminder.notificationID
    }
}

struct HabitBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
