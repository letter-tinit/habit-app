//
//  HabitNotificationScheduler.swift
//  Habit
//
//  Created by Codex on 27/5/26.
//

import Foundation
import UserNotifications

enum HabitNotificationScheduler {
    static func rescheduleNotifications(for habit: Habit) {
        cancelNotifications(for: habit)

        guard !habit.isArchived else {
            return
        }

        let enabledReminders = habit.reminders.filter(\.isEnabled)
        guard !enabledReminders.isEmpty else {
            return
        }

        requestAuthorizationIfNeeded { isAuthorized in
            guard isAuthorized else {
                return
            }

            for reminder in enabledReminders {
                scheduleReminder(reminder, for: habit)
            }
        }
    }

    static func cancelNotifications(for habit: Habit) {
        let identifiers = habit.reminders.flatMap(notificationIdentifiers(for:))
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    completion(true)
                }
            case .notDetermined:
                notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { isGranted, error in
                    if let error {
                        let message = "Failed to request notification authorization: \(error)"
                        DispatchQueue.main.async {
                            Logger.error(message)
                        }
                    }
                    DispatchQueue.main.async {
                        completion(isGranted)
                    }
                }
            case .denied:
                DispatchQueue.main.async {
                    completion(false)
                }
            @unknown default:
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }

    private static func scheduleReminder(_ reminder: HabitReminder, for habit: Habit) {
        let weekdays = notificationWeekdays(for: reminder, habit: habit)

        for weekday in weekdays {
            let content = UNMutableNotificationContent()
            content.title = habit.name
            content.body = reminderBody(for: habit)
            content.sound = .default

            var dateComponents = AppCalendar.current.dateComponents([.hour, .minute], from: reminder.time)
            dateComponents.weekday = weekday + 1

            let request = UNNotificationRequest(
                identifier: notificationIdentifier(for: reminder, weekday: weekday),
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    let message = "Failed to schedule habit notification: \(error)"
                    DispatchQueue.main.async {
                        Logger.error(message)
                    }
                }
            }
        }
    }

    private static func reminderBody(for habit: Habit) -> String {
        switch habit.goalType {
        case .todo:
            "Time to complete this habit."
        case .count:
            "Time to work on \(habit.goalCount) \(habit.goalUnit)."
        }
    }

    private static func notificationWeekdays(for reminder: HabitReminder, habit: Habit) -> [Int] {
        let weekdays = reminder.daysOfWeek.isEmpty ? scheduledWeekdays(for: habit) : reminder.daysOfWeek
        return weekdays.filter { (0...6).contains($0) }.sorted()
    }

    private static func scheduledWeekdays(for habit: Habit) -> [Int] {
        switch habit.frequency {
        case .daily:
            Array(0...6)
        case .weekday:
            Array(1...5)
        case .weekend:
            [0, 6]
        case .custom:
            habit.targetDaysOfWeek
        }
    }

    private static func notificationIdentifiers(for reminder: HabitReminder) -> [String] {
        (0...6).map { notificationIdentifier(for: reminder, weekday: $0) }
    }

    private static func notificationIdentifier(for reminder: HabitReminder, weekday: Int) -> String {
        "\(reminder.notificationID)-weekday-\(weekday)"
    }
}
