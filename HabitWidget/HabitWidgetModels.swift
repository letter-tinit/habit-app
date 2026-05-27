//
//  HabitWidgetModels.swift
//  HabitWidget
//
//  Created by Codex on 27/5/26.
//

import Foundation
import SwiftUI

enum HabitWidgetStore {
    static let appGroupIdentifier = "group.com.tinit.Habit"

    private static let snapshotKey = "habit.widget.snapshot"
    private static let pendingActionsKey = "habit.widget.pendingActions"

    static func loadSnapshot() -> HabitWidgetSnapshot {
        guard let data = userDefaults?.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(HabitWidgetSnapshot.self, from: data)
        else {
            return HabitWidgetSnapshot(date: Date(), habits: [])
        }

        return snapshot.forToday()
    }

    static func saveSnapshot(_ snapshot: HabitWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        userDefaults?.set(data, forKey: snapshotKey)
    }

    static func appendAction(_ action: HabitWidgetAction) {
        var actions = loadPendingActions()
        actions.append(action)

        guard let data = try? JSONEncoder().encode(actions) else {
            return
        }

        userDefaults?.set(data, forKey: pendingActionsKey)
    }

    private static func loadPendingActions() -> [HabitWidgetAction] {
        guard let data = userDefaults?.data(forKey: pendingActionsKey) else {
            return []
        }

        return (try? JSONDecoder().decode([HabitWidgetAction].self, from: data)) ?? []
    }

    private static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
}

struct HabitWidgetSnapshot: Codable {
    var date: Date
    var habits: [HabitWidgetItem]
}

struct HabitWidgetItem: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var goalTypeRawValue: String
    var goalCount: Int
    var goalUnit: String
    var completedCount: Int
    var currentStreak: Int
    var scheduledWeekdays: [Int]

    var isCompleted: Bool {
        completedCount >= goalCount
    }

    var progressText: String {
        goalTypeRawValue == "count" ? "\(completedCount)/\(goalCount) \(goalUnit)" : "\(completedCount)/\(goalCount)"
    }
}

private extension HabitWidgetSnapshot {
    func forToday() -> HabitWidgetSnapshot {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date()) - 1

        var todayHabits = habits.filter { $0.scheduledWeekdays.contains(weekday) }
        if !calendar.isDate(date, inSameDayAs: Date()) {
            todayHabits = todayHabits.map { habit in
                var habit = habit
                habit.completedCount = 0
                return habit
            }
        }

        return HabitWidgetSnapshot(date: Date(), habits: todayHabits)
    }
}

struct HabitWidgetAction: Codable, Identifiable {
    var id: UUID
    var habitID: UUID
    var completedCount: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        habitID: UUID,
        completedCount: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.habitID = habitID
        self.completedCount = completedCount
        self.createdAt = createdAt
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 6:
            r = int >> 16
            g = int >> 8 & 0xFF
            b = int & 0xFF
        default:
            r = 78
            g = 205
            b = 196
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
