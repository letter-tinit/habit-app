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
    @State private var habitStore: HabitStore
    @Environment(\.scenePhase) private var scenePhase
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
        _habitStore = State(initialValue: HabitStore(modelContext: container.mainContext))

        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            MainTabScreen()
                .modelContainer(container)
                .environment(habitStore)
                .preferredColorScheme(preferredColorScheme)
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    habitStore.rescheduleHabitNotifications()
                }
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch habitStore.colorScheme {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
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
