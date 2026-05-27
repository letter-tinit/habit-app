//
//  HabitWidgetBridge.swift
//  Habit
//
//  Created by Codex on 27/5/26.
//

import Foundation
import WidgetKit

enum HabitWidgetBridge {
    static let appGroupIdentifier = "group.com.tinit.Habit"

    private static let snapshotKey = "habit.widget.snapshot"
    private static let pendingActionsKey = "habit.widget.pendingActions"

    static func loadPendingActions() -> [HabitWidgetAction] {
        guard let data = userDefaults?.data(forKey: pendingActionsKey) else {
            return []
        }

        return (try? JSONDecoder().decode([HabitWidgetAction].self, from: data)) ?? []
    }

    static func clearPendingActions() {
        userDefaults?.removeObject(forKey: pendingActionsKey)
    }

    static func saveSnapshot(_ snapshot: HabitWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        userDefaults?.set(data, forKey: snapshotKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "HabitTrackingWidget")
    }

    private static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
}

struct HabitWidgetSnapshot: Codable {
    var date: Date
    var habits: [HabitWidgetItem]
}

struct HabitWidgetItem: Codable, Identifiable {
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
