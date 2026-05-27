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
    case overview = "Overview"
    case statistic = "Statistic"
    case profile = "Profile"
    
    var symbolImage: String {
        return switch self {
        case .home:
            "figure.run"
        case .overview:
            "chart.bar.xaxis"
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
        case .overview:
                .emeraldGreen
        case .statistic:
                .emeraldGreen
        case .profile:
                .royalBlue
        }
    }
}

struct MainTabScreen: View {
    @Environment(HabitStore.self) private var habitStore
    @State private var activeTab: AppTab = .home
    @State private var homeRouter = HomeRouter()
    @State private var overviewRouter = OverviewRouter()
    @State private var statisticalRouter = StatisticalRouter()
    @State private var profileRouter = ProfileRouter()
    
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
                Image(module: AppTab.home.symbolImage)
            }
            
            Tab(value: AppTab.overview) {
                AppNavigationStack(path: $overviewRouter.path) {
                    AggregateStatisticalScreen()
                } destination: { _ in }
            } label: {
                Image(module: AppTab.overview.symbolImage)
            }
            
            Tab(value: AppTab.statistic) {
                AppNavigationStack(path: $statisticalRouter.path) {
                    StatisticalScreen()
                } destination: { _ in }
            } label: {
                Image(module: AppTab.statistic.symbolImage)
            }
            
            Tab(value: AppTab.profile) {
                AppNavigationStack(path: $profileRouter.path) {
                    ProfileScreen()
                        .environment(profileRouter)
                } destination: { route in
                    switch route {
                    case .editProfile:
                        EditProfileScreen()
                            .environment(profileRouter)
                    }
                }
            } label: {
                Image(module: AppTab.profile.symbolImage)
            }
        }
        .tint(.cyan)
        .toolbarBackground(.hidden, for: .tabBar)
        .onChange(of: activeTab) { _, _ in
            Haptic.selection()
        }
    }
    
    private var habitStoreProfileName: String {
        habitStore.userProfile?.displayName ?? "You"
    }
    
    private var habitStoreProfileAvatarData: Data? {
        habitStore.userProfile?.avatarData
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
