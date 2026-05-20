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
    case profile = "Profile"
    
    var symbolImage: String {
        return switch self {
        case .home:
            "figure.run"
        case .profile:
            "person.crop.circle"
        }
    }
    
    var tintColor: Color {
        switch self {
        case .home:
                .rosePink
        case .profile:
                .aquaCyan
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
                    case .habitDetail(let habitID):
                        HabitDetailScreen(habitID: habitID)
                            .environment(homeRouter)
                            .tint(.black)
                    case .createHabit:
                        CreateHabitScreen()
                            .environment(homeRouter)
                            .tint(.black)
                    }
                }
            } label: {
                Image(systemName: AppTab.home.symbolImage)
            }

            Tab(value: AppTab.profile) {
                ProfileScreen()
            } label: {
                Image(systemName: AppTab.profile.symbolImage)
            }
        }
        .tint(activeTab.tintColor)
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
