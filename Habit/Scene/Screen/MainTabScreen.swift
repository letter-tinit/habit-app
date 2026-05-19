//
//  MainTabScreen.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import SwiftUI
import SwiftData

enum AppTab: String {
    case home = "Home"
    
    var symbolImage: String {
        return switch self {
        case .home:
            "figure.run"
        }
    }
}

struct MainTabScreen: View {
    @State private var activeTab: AppTab = .home
    @State private var homeRouter = HomeRouter()
    
    var body: some View {
        TabView(selection: $activeTab) {
            Tab(value: AppTab.home) {
                AppNavigationStack(path: $homeRouter.path) {
                    HomeScreen()
                        .environment(homeRouter)
                        .tint(.black)
                } destination: { route in
                    switch route {
                    case .habitDetail:
                        HabitDetailScreen()
                    }
                }
            } label: {
                Image(systemName: AppTab.home.symbolImage)
            }
        }
        .tint(.rosePink)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Habit.self, HabitEntry.self, HabitCategory.self, HabitReminder.self, UserProfile.self,
        configurations: config
    )

    MainTabScreen()
        .tint(.black)
        .modelContainer(container)
        .environment(HabitStore(modelContext: container.mainContext))
}
