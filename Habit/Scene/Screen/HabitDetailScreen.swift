//
//  HabitDetailScreen.swift
//  Habit
//
//  Created by TiniT on 29/4/26.
//

import SwiftUI

struct HabitDetailScreen: View {
    @Binding var habit: Habit
    @FocusState private var isFocused: Bool
    private var focusBinding: Binding<Bool> {
        Binding(
            get: { isFocused },
            set: { isFocused = $0 }
        )
    }
    var body: some View {
        BaseScreen($habit.name, isFocused: focusBinding) {
            
        }
    }
}

#Preview {
    HabitDetailScreen(habit: .constant(.mock))
}
