//
//  HabitDetailScreen.swift
//  Habit
//
//  Created by TiniT on 29/4/26.
//

import SwiftUI

struct HabitDetailScreen: View {
    @Environment(HabitStore.self) private var habitStore

    var body: some View {
        Group {
            if let habit = habitStore.selectedHabit {
                HabitDetailContent(habit: habit)
            } else {
                Text("No habit selected")
            }
        }
    }
}

struct HabitDetailContent: View {
    @Environment(HabitStore.self) private var habitStore
    @Environment(\.dismiss) private var dismiss
    @Bindable var habit: Habit
    @FocusState private var isFocused: Bool

    var body: some View {
        let originalEmoji = habit.emoji
        BaseScreen($habit.name) {
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
                    .keyboardType(.emoji)
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
        // MARK: - ToolBar
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    baseAnimation {
                        if habitStore.deleteSelectedHabit() {
                            dismiss()
                        }
                    }
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }
}

#Preview {
    HabitDetailScreen()
}
