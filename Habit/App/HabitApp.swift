//
//  HabitApp.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import SwiftUI

@main
struct HabitApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabScreen()
//                .tint(.black)
                .environment(HabitStore())
        }
    }
}
