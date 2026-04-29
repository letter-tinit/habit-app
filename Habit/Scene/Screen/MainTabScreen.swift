//
//  MainTabScreen.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import SwiftUI

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
    }
}

#Preview {
    MainTabScreen()
        .tint(.black)
        .environment(HabitStore())
}
