//
//  HabitApp.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import SwiftUI
import SwiftData

@main
struct HabitApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Habit.self,
            HabitEntry.self,
            HabitCategory.self,
            HabitReminder.self,
            UserProfile.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabScreen()
                .modelContainer(container)
                .environment(HabitStore(modelContext: container.mainContext))
        }
    }
}
