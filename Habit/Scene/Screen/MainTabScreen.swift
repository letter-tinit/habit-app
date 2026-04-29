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
            "house"
        }
    }
}

struct MainTabScreen: View {
    @State private var activeTab: AppTab = .home
    
    var body: some View {
        TabView(selection: $activeTab) {
            Tab(AppTab.home.rawValue, systemImage: AppTab.home.symbolImage, value: .home) {
                NavigationStack {
                    HomeScreen()
                }
            }
        }
    }
}

#Preview {
    MainTabScreen()
        .tint(.black)
        .environment(HabitStore())
}
