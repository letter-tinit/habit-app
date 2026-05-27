//
//  HabitApp.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct HabitApp: App {
    let container: ModelContainer
    private let notificationDelegate = AppNotificationDelegate()

    init() {
        let schema = Schema([
            Habit.self,
            HabitEntry.self,
            HabitReminder.self,
            UserProfile.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            MainTabScreen()
                .modelContainer(container)
                .environment(HabitStore(modelContext: container.mainContext))
        }
    }
}

private final class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
