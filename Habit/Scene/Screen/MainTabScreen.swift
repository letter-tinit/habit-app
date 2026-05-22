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
    case statistic = "Statistic"
    case profile = "Profile"

    var symbolImage: String {
        return switch self {
        case .home:
            "figure.run"
        case .statistic:
            "heart.text.clipboard"
        case .profile:
            "person"
        }
    }
    
    var tintColor: Color {
        switch self {
        case .home:
                .rosePink
        case .statistic:
                .emeraldGreen
        case .profile:
                .royalBlue
        }
    }
}

struct MainTabScreen: View {
    @State private var activeTab: AppTab = .statistic
    @State private var homeRouter = HomeRouter()
    
    var body: some View {
        TabView(selection: $activeTab) {
            Tab(value: AppTab.home) {
                AppNavigationStack(path: $homeRouter.path) {
                    HomeScreen()
                        .environment(homeRouter)
                } destination: { route in
                    switch route {
                    case .habitDetail(let habitID):
                        HabitDetailScreen(habitID: habitID)
                            .environment(homeRouter)
                    case .createHabit:
                        CreateHabitScreen()
                            .environment(homeRouter)
                    }
                }
            } label: {
                Image(systemName: AppTab.home.symbolImage)
            }
            
            Tab(value: AppTab.statistic) {
                StatisticalScreen()
            } label: {
                Image(systemName: AppTab.statistic.symbolImage)
            }

            Tab(value: AppTab.profile) {
                ProfileScreen()
            } label: {
                Image(systemName: AppTab.profile.symbolImage)
            }
        }
        .tint(activeTab.tintColor)
        .toolbarBackground(.hidden, for: .tabBar)
        .onChange(of: activeTab) { _, _ in
            Haptic.selection()
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Habit.self, HabitEntry.self, HabitReminder.self, UserProfile.self,
        configurations: config
    )

    MainTabScreen()
        .modelContainer(container)
        .environment(HabitStore(modelContext: container.mainContext))
}
