//
//  HabitStore.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import Observation
import Foundation
import SwiftData

struct HabitStatisticSummary {
    let progress: Double
    let scheduledDays: Int
    let completedDays: Int
    let totalCompletedCount: Int
    let totalTargetCount: Int
}

@Observable
final class HabitStore {
    // MARK: - Dependencies
    private var modelContext: ModelContext

    var homeTitle: String = AppString.Home.today
    var profileTitle: String = AppString.ScreenTitle.profile
    var habits: [Habit] = []
    var filteredHabit: [Habit] {
        habits
            .filter(isHabit)
            .sorted { first, second in
                let firstIsComplete = isComplete(for: first, on: selectedDate)
                let secondIsComplete = isComplete(for: second, on: selectedDate)

                if firstIsComplete != secondIsComplete {
                    return !firstIsComplete
                }

                return first.sortOrder < second.sortOrder
            }
    }
    var selectedHabit: Habit?
    private(set) var selectedDate: Date = Date()
    var weekStartsOnMonday: Bool {
        userProfile?.weekStartsOnMonday ?? true
    }

    var orderedWeekdays: [Int] {
        weekStartsOnMonday
        ? [1, 2, 3, 4, 5, 6, 0]
        : [0, 1, 2, 3, 4, 5, 6]
    }

    // MARK: - STATISTICAL
    var usesCompactStatisticsView: Bool = false {
        didSet {
            guard usesCompactStatisticsView != oldValue else {
                return
            }
            updateUsesSimplifiedStatisticsMode(usesCompactStatisticsView)
        }
    }

    // MARK: - PROFILE
    var userProfile: UserProfile?

    // MARK: - Constructor
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchUserProfile()
        fetchHabits()
    }
}

// MARK: - Home

extension HabitStore {
    func backToday() {
        didChangeSelecteDate(Date())
    }

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

    func isScheduled(_ habit: Habit, on date: Date) -> Bool {
        shouldSchedule(habit, on: date, calendar: AppCalendar.current)
    }

    /// Input: a date param
    /// Output: check is input date is selected Date or not
    func isSelectedDay(_ date: Date) -> Bool {
        date.isEqual(with: selectedDate)
    }
}

// MARK: - Profile

extension HabitStore {
    func fetchUserProfile() {
        let descriptor = FetchDescriptor<UserProfile>()

        do {
            if let existingProfile = try modelContext.fetch(descriptor).first {
                userProfile = existingProfile
                AppCalendar.weekStartsOnMonday = existingProfile.weekStartsOnMonday
                usesCompactStatisticsView = existingProfile.usesSimplifiedStatisticsMode
                profileTitle = userProfile?.displayName ?? AppString.ScreenTitle.profile
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

    func updateUsesSimplifiedStatisticsMode(_ enabled: Bool) {
        if userProfile == nil {
            fetchUserProfile()
        }

        userProfile?.usesSimplifiedStatisticsMode = enabled
        _ = save()
    }

    func updateProfile(displayName: String, avatarOriginalData: Data?, avatarData: Data?) {
        if userProfile == nil {
            fetchUserProfile()
        }

        userProfile?.displayName = displayName
        userProfile?.avatarOriginalData = avatarOriginalData
        userProfile?.avatarData = avatarData
        _ = save()
    }
}

// MARK: - Backup

extension HabitStore {
    func exportBackupData() throws -> Data {
        if userProfile == nil {
            fetchUserProfile()
        }

        let backup = HabitBackup(profile: userProfile, habits: habits)
        try backup.validate()
        return try encodeBackup(backup)
    }

    func backupSummary(for data: Data) throws -> HabitBackupSummary {
        let backup = try decodeAndValidateBackup(from: data)
        return backup.summary
    }

    func safetyBackups() -> [URL] {
        do {
            let directory = try backupDirectory()
            let backupURLs = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )

            return backupURLs
                .filter { $0.pathExtension.lowercased() == "json" }
                .sorted { first, second in
                    creationDate(for: first) > creationDate(for: second)
                }
        } catch {
            Logger.error("Failed to load safety backups: \(error)")
            return []
        }
    }

    func createPreImportBackup() throws -> URL {
        let data = try exportBackupData()
        let directory = try backupDirectory()
        let filename = "HabitBackup-BeforeImport-\(Self.backupFilenameDateFormatter.string(from: Date())).json"
        let url = directory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    func decodeAndValidateBackup(from data: Data) throws -> HabitBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let backup = try decoder.decode(HabitBackup.self, from: data)
        try backup.validate()
        return backup
    }

    func encodeBackup(_ backup: HabitBackup) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    func importBackupData(_ data: Data) throws {
        _ = try createPreImportBackup()
        let backup = try decodeAndValidateBackup(from: data)
        try replaceCurrentData(with: backup)
        fetchUserProfile()
        fetchHabits()
    }
}

// MARK: - Habits

extension HabitStore {
    func fetchHabits() {
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [
                SortDescriptor(\.sortOrder),
                SortDescriptor(\.createdAt, order: .reverse)
            ]
        )
        do {
            habits = try modelContext.fetch(descriptor)
        } catch {
            Logger.error("Failed to fetch habits: \(error)")
            habits = []
        }
    }

    func addHabit(_ habit: Habit) {
        habit.sortOrder = nextHabitSortOrder()
        modelContext.insert(habit)
        if save() {
            fetchHabits()
        }
    }

    func moveFilteredHabits(from source: IndexSet, to destination: Int) {
        let visibleHabitIDs = filteredHabit.map(\.id)
        let visibleHabitIDSet = Set(visibleHabitIDs)
        let reorderedVisibleIDs = visibleHabitIDs.moving(from: source, to: destination)

        var reorderedVisibleIDIndex = 0
        let reorderedGlobalIDs = habits.map { habit in
            guard visibleHabitIDSet.contains(habit.id) else {
                return habit.id
            }

            defer {
                reorderedVisibleIDIndex += 1
            }
            return reorderedVisibleIDs[reorderedVisibleIDIndex]
        }

        for (index, habitID) in reorderedGlobalIDs.enumerated() {
            habit(id: habitID)?.sortOrder = index
        }

        if save() {
            fetchHabits()
        } else {
            fetchHabits()
        }
    }

    func updateHabit(
        _ habit: Habit,
        name: String,
        description: String,
        icon: String,
        colorHex: String,
        frequency: HabitFrequency,
        targetDaysOfWeek: [Int],
        goalType: GoalType,
        goalCount: Int,
        goalUnit: String
    ) {
        habit.name = name
        habit.habitDescription = description
        habit.icon = icon
        habit.colorHex = colorHex
        habit.frequency = frequency
        habit.targetDaysOfWeek = targetDaysOfWeek
        habit.goalType = goalType
        habit.goalCount = goalCount
        habit.goalUnit = goalUnit

        updateStreaks(for: habit)

        if !save() {
            fetchHabits()
        }
    }

    @discardableResult
    func archiveHabit(_ habit: Habit) -> Bool {
        guard habit.archivedAt == nil else { return true }

        habit.archivedAt = Date()

        if save() {
            fetchHabits()
            return true
        } else {
            habit.archivedAt = nil
            fetchHabits()
            return false
        }
    }

    @discardableResult
    func unarchiveHabit(_ habit: Habit) -> Bool {
        guard habit.archivedAt != nil else { return true }

        let archivedAt = habit.archivedAt
        habit.archivedAt = nil

        if save() {
            fetchHabits()
            return true
        } else {
            habit.archivedAt = archivedAt
            fetchHabits()
            return false
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
}

// MARK: - Habit Entries

extension HabitStore {
    var canEditSelectedDateEntry: Bool {
        !selectedDate.isFutureDay()
    }

    func updateHabitEntry(_ habit: Habit, completedCount: Int, note: String? = nil) {
        guard canEditSelectedDateEntry else {
            Haptic.warning()
            return
        }

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
        guard canEditSelectedDateEntry else {
            Haptic.warning()
            return
        }

        let calendar = AppCalendar.current
        let targetDate = calendar.startOfDay(for: selectedDate)

        if let existingEntry = habit.entries.first(where: {
            $0.date.isEqual(with: targetDate)
        }) {
            guard existingEntry.completedCount != 0 else {
                return
            }
            Haptic.warning()
            existingEntry.completedCount = 0
            existingEntry.updatedAt = Date()
        }

        updateStreaks(for: habit)
        _ = save()
    }
}

// MARK: - Streak Helpers

private extension HabitStore {
    func updateStreaks(for habit: Habit) {
        let calendar = AppCalendar.current
        let completedDates = Set(
            habit.entries
                .filter { $0.isCompleted }
                .map { calendar.startOfDay(for: $0.date) }
                .filter { shouldSchedule(habit, on: $0, calendar: calendar) }
        )

        guard let lastCompleted = completedDates.max() else {
            habit.currentStreak = 0
            habit.longestStreak = 0
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

    func longestStreak(
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

    func streakEnding(
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

    func previousScheduledDate(
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
}

// MARK: - Scheduling

private extension HabitStore {
    func shouldSchedule(
        _ habit: Habit,
        on date: Date,
        calendar: Calendar
    ) -> Bool {
        let day = calendar.startOfDay(for: date)
        let createdDay = calendar.startOfDay(for: habit.createdAt)

        guard day >= createdDay else {
            return false
        }

        if let archivedAt = habit.archivedAt {
            let archivedDay = calendar.startOfDay(for: archivedAt)
            guard day <= archivedDay else {
                return false
            }
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
}

// MARK: - Persistence

private extension HabitStore {
    func save() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            Logger.error("Failed to save context: \(error)")
            return false
        }
    }
}

// MARK: - Backup Helpers

enum HabitBackupError: LocalizedError {
    case unsupportedSchemaVersion(Int)
    case invalidData(String)
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            "This backup uses schema version \(version), which this app cannot import."
        case .invalidData(let message):
            message
        case .saveFailed:
            "The backup could not be saved after import."
        }
    }
}

private extension HabitStore {
    static let backupFilenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter
    }()

    func backupDirectory() throws -> URL {
        let applicationSupportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let backupURL = applicationSupportURL.appendingPathComponent("Backups", isDirectory: true)
        try FileManager.default.createDirectory(at: backupURL, withIntermediateDirectories: true)
        return backupURL
    }

    func creationDate(for url: URL) -> Date {
        let values = try? url.resourceValues(forKeys: [.creationDateKey])
        return values?.creationDate ?? .distantPast
    }

    func nextHabitSortOrder() -> Int {
        (habits.map(\.sortOrder).max() ?? -1) + 1
    }

    func replaceCurrentData(with backup: HabitBackup) throws {
        try deleteExistingBackupData()
        restoreProfile(from: backup.profile)
        restoreHabits(from: backup.habits)

        guard save() else {
            modelContext.rollback()
            fetchUserProfile()
            fetchHabits()
            throw HabitBackupError.saveFailed
        }
    }

    func deleteExistingBackupData() throws {
        try modelContext.fetch(FetchDescriptor<HabitEntry>()).forEach { entry in
            modelContext.delete(entry)
        }
        try modelContext.fetch(FetchDescriptor<HabitReminder>()).forEach { reminder in
            modelContext.delete(reminder)
        }
        try modelContext.fetch(FetchDescriptor<Habit>()).forEach { habit in
            modelContext.delete(habit)
        }
        try modelContext.fetch(FetchDescriptor<UserProfile>()).forEach { profile in
            modelContext.delete(profile)
        }
    }

    func restoreProfile(from backup: UserProfileBackup?) {
        let profile = UserProfile(displayName: backup?.displayName ?? "You")

        if let backup {
            profile.id = backup.id
            profile.avatarOriginalData = backup.avatarOriginalData
            profile.avatarData = backup.avatarData
            profile.weekStartsOnMonday = backup.weekStartsOnMonday
            profile.usesSimplifiedStatisticsMode = backup.usesSimplifiedStatisticsMode
            profile.defaultReminderTime = backup.defaultReminderTime
            profile.themeColorHex = backup.themeColorHex
            profile.totalCompletions = backup.totalCompletions
            profile.totalHabitsCreated = backup.totalHabitsCreated
            profile.longestOverallStreak = backup.longestOverallStreak
            profile.joinedAt = backup.joinedAt
        }

        modelContext.insert(profile)
        userProfile = profile
        AppCalendar.weekStartsOnMonday = profile.weekStartsOnMonday
        usesCompactStatisticsView = profile.usesSimplifiedStatisticsMode
    }

    func restoreHabits(from backups: [HabitBackupItem]) {
        for backup in backups {
            let habit = Habit(
                name: backup.name,
                description: backup.habitDescription,
                icon: backup.icon,
                colorHex: backup.colorHex,
                frequency: backup.frequency,
                targetDaysOfWeek: backup.targetDaysOfWeek,
                goalType: backup.goalType,
                goalCount: backup.goalCount,
                goalUnit: backup.goalUnit
            )

            habit.id = backup.id
            habit.createdAt = backup.createdAt
            habit.archivedAt = backup.archivedAt
            habit.sortOrder = backup.sortOrder
            habit.reminderTime = backup.reminderTime
            habit.currentStreak = backup.currentStreak
            habit.longestStreak = backup.longestStreak
            habit.lastCompletedDate = backup.lastCompletedDate

            restoreEntries(backup.entries, into: habit)
            restoreReminders(backup.reminders, into: habit)
            modelContext.insert(habit)
        }
    }

    func restoreEntries(_ backups: [HabitEntryBackupItem], into habit: Habit) {
        for backup in backups {
            let entry = HabitEntry(
                date: backup.date,
                completedCount: backup.completedCount,
                note: backup.note
            )

            entry.id = backup.id
            entry.mood = backup.mood
            entry.createdAt = backup.createdAt
            entry.updatedAt = backup.updatedAt
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }
    }

    func restoreReminders(_ backups: [HabitReminderBackupItem], into habit: Habit) {
        for backup in backups {
            let reminder = HabitReminder(
                time: backup.time,
                daysOfWeek: backup.daysOfWeek,
                isEnabled: backup.isEnabled
            )

            reminder.id = backup.id
            reminder.notificationID = backup.notificationID
            reminder.habit = habit
            habit.reminders.append(reminder)
            modelContext.insert(reminder)
        }
    }
}

// MARK: - Statistics

extension HabitStore {
    func monthDates(containing date: Date) -> [Date] {
        dates(in: .month, containing: date)
    }

    func weekDates(containing date: Date) -> [Date] {
        dates(in: .weekOfYear, containing: date)
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

    func completionRatio(for habit: Habit, on date: Date) -> Double {
        let calendar = AppCalendar.current
        let targetDate = calendar.startOfDay(for: date)

        guard shouldSchedule(habit, on: targetDate, calendar: calendar),
              habit.goalCount > 0
        else {
            return 0
        }

        let entry = habit.entries.first {
            calendar.isDate($0.date, inSameDayAs: targetDate)
        }
        let completedCount = entry?.completedCount ?? 0

        return min(Double(completedCount) / Double(habit.goalCount), 1.0)
    }

    func isComplete(on date: Date) -> Bool {
        let calendar = AppCalendar.current
        let targetDate = calendar.startOfDay(for: date)

        let scheduledHabits = habits.filter {
            shouldSchedule($0, on: targetDate, calendar: calendar)
        }

        guard !scheduledHabits.isEmpty else {
            return false
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

        let ratio = totalRatio / Double(scheduledHabits.count)

        return ratio == 1.0
    }

    func isComplete(for habit: Habit, on date: Date) -> Bool {
        let calendar = AppCalendar.current
        let targetDate = calendar.startOfDay(for: date)

        guard shouldSchedule(habit, on: targetDate, calendar: calendar),
              habit.goalCount > 0
        else {
            return false
        }

        let entry = habit.entries.first {
            calendar.isDate($0.date, inSameDayAs: targetDate)
        }
        return entry?.isCompleted ?? false
    }

    func completionRatioForMonth(containing date: Date) -> Double {
        let dates = monthDates(containing: date)
        return completionRatio(for: dates)
    }

    func completionRatioForMonth(for habit: Habit, containing date: Date) -> Double {
        let dates = monthDates(containing: date)
        return completionRatio(for: habit, dates: dates)
    }

    func completionRatioForWeek(containing date: Date) -> Double {
        let dates = weekDates(containing: date)
        return completionRatio(for: dates)
    }

    func completionRatioForWeek(for habit: Habit, containing date: Date) -> Double {
        let dates = weekDates(containing: date)
        return completionRatio(for: habit, dates: dates)
    }

    func completionRatioForYear(containing date: Date) -> Double {
        completionRatio(for: yearDates(containing: date))
    }

    func completionRatioForYear(for habit: Habit, containing date: Date) -> Double {
        completionRatio(for: habit, dates: yearDates(containing: date))
    }

    func statisticSummary(
        for habit: Habit,
        scope: StatisticsScope,
        containing date: Date
    ) -> HabitStatisticSummary {
        let dates: [Date]

        switch scope {
        case .week:
            dates = weekDates(containing: date)
        case .month:
            dates = monthDates(containing: date)
        case .year:
            dates = yearDates(containing: date)
        }

        return statisticSummary(for: habit, dates: dates)
    }

    func statisticSummary(
        scope: StatisticsScope,
        containing date: Date
    ) -> HabitStatisticSummary {
        let dates: [Date]

        switch scope {
        case .week:
            dates = weekDates(containing: date)
        case .month:
            dates = monthDates(containing: date)
        case .year:
            dates = yearDates(containing: date)
        }

        return statisticSummary(dates: dates)
    }

    func statisticSummary(dates: [Date]) -> HabitStatisticSummary {
        aggregateStatisticSummary(dates: dates)
    }

    func yearDates(containing date: Date) -> [Date] {
        dates(in: .year, containing: date)
    }

    func dates(scope: StatisticsScope, containing date: Date) -> [Date] {
        switch scope {
        case .week:
            weekDates(containing: date)
        case .month:
            monthDates(containing: date)
        case .year:
            yearDates(containing: date)
        }
    }
}

// MARK: - Statistics Helpers

private extension HabitStore {
    func dates(
        in component: Calendar.Component,
        containing date: Date
    ) -> [Date] {
        let calendar = AppCalendar.current

        guard let interval = calendar.dateInterval(of: component, for: date) else {
            return []
        }

        var dates: [Date] = []
        var currentDate = calendar.startOfDay(for: interval.start)

        while currentDate < interval.end {
            dates.append(currentDate)

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }

            currentDate = nextDate
        }

        return dates
    }

    func completionRatio(for dates: [Date]) -> Double {
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

    func completionRatio(for habit: Habit, dates: [Date]) -> Double {
        let calendar = AppCalendar.current
        let validDates = dates.filter {
            shouldSchedule(habit, on: $0, calendar: calendar)
        }

        guard !validDates.isEmpty else {
            return 0
        }

        let totalRatio = validDates.reduce(0.0) { result, date in
            result + completionRatio(for: habit, on: date)
        }

        return totalRatio / Double(validDates.count)
    }

    func statisticSummary(for habit: Habit, dates: [Date]) -> HabitStatisticSummary {
        let calendar = AppCalendar.current
        let scheduledDates = dates.filter { shouldSchedule(habit, on: $0, calendar: calendar) }
        let archivedDay = habit.archivedAt.map { calendar.startOfDay(for: $0) }

        guard !scheduledDates.isEmpty else {
            return HabitStatisticSummary(
                progress: 0,
                scheduledDays: 0,
                completedDays: 0,
                totalCompletedCount: 0,
                totalTargetCount: 0
            )
        }

        let entriesByDate = habit.entries.reduce(into: [Date: HabitEntry]()) { result, entry in
            let entryDay = calendar.startOfDay(for: entry.date)
            if let archivedDay, entryDay > archivedDay {
                return
            }
            result[entryDay] = entry
        }

        let completedCount = scheduledDates.reduce(0) { result, date in
            result + min(entriesByDate[calendar.startOfDay(for: date)]?.completedCount ?? 0, habit.goalCount)
        }
        let completedDays = scheduledDates.filter {
            completionRatio(for: habit, on: $0) >= 1
        }.count
        let targetCount = scheduledDates.count * habit.goalCount

        return HabitStatisticSummary(
            progress: completionRatio(for: habit, dates: dates),
            scheduledDays: scheduledDates.count,
            completedDays: completedDays,
            totalCompletedCount: completedCount,
            totalTargetCount: targetCount
        )
    }

    func aggregateStatisticSummary(dates: [Date]) -> HabitStatisticSummary {
        let calendar = AppCalendar.current
        var scheduledDayCount = 0
        var completedDayCount = 0
        var totalCompletedCount = 0
        var totalTargetCount = 0

        for date in dates {
            let scheduledHabits = habits.filter {
                shouldSchedule($0, on: date, calendar: calendar)
            }

            guard !scheduledHabits.isEmpty else {
                continue
            }

            scheduledDayCount += 1

            var completedCountForDate = 0
            var targetCountForDate = 0
            for habit in scheduledHabits where habit.goalCount > 0 {
                let entry = habit.entries.first {
                    calendar.isDate($0.date, inSameDayAs: date)
                }
                completedCountForDate += min(entry?.completedCount ?? 0, habit.goalCount)
                targetCountForDate += habit.goalCount
            }

            totalCompletedCount += completedCountForDate
            totalTargetCount += targetCountForDate

            if targetCountForDate > 0 && completedCountForDate >= targetCountForDate {
                completedDayCount += 1
            }
        }

        let progress = totalTargetCount == 0
        ? 0
        : min(Double(totalCompletedCount) / Double(totalTargetCount), 1)

        return HabitStatisticSummary(
            progress: progress,
            scheduledDays: scheduledDayCount,
            completedDays: completedDayCount,
            totalCompletedCount: totalCompletedCount,
            totalTargetCount: totalTargetCount
        )
    }
}

private extension Array {
    func moving(from source: IndexSet, to destination: Int) -> [Element] {
        var result = self
        let movingElements = source.map { result[$0] }

        for index in source.sorted(by: >) {
            result.remove(at: index)
        }

        let removedBeforeDestination = source.filter { $0 < destination }.count
        let adjustedDestination = destination - removedBeforeDestination
        result.insert(contentsOf: movingElements, at: adjustedDestination)

        return result
    }
}
