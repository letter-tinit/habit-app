//
//  HabitDetailScreen.swift
//  Habit
//
//  Created by TiniT on 29/4/26.
//

import SwiftUI

struct HabitDetailScreen: View {
    @Environment(HabitStore.self) private var habitStore
    @FocusState private var isFocused: Bool
    private var focusBinding: Binding<Bool> {
        Binding(
            get: { isFocused },
            set: { isFocused = $0 }
        )
    }
    var body: some View {
        @Bindable var habit = habitStore.selectedHabit
        let originalEmoji = habit.emoji
        BaseScreen($habit.name, isFocused: focusBinding) {
            VStack {
                Button {
                    baseAnimation {
                        isFocused = true
                    }
                } label: {
                    Text(habit.emoji)
                        .font(.headline)
                }
                
                TextField("", text: $habit.emoji)
                    .frame(height: 0)
                    .opacity(0)
                    .focused($isFocused)
                    .keyboardType(.emoji ?? .default)
                    .onChange(of: habit.emoji) { _, newValue in
                        if let last = newValue.last, last.isEmoji {
                            habit.emoji = String(last)
                        } else {
                            habit.emoji = originalEmoji
                        }
                    }
                
                Spacer()
            }
        }
    }
}

#Preview {
    HabitDetailScreen()
}
