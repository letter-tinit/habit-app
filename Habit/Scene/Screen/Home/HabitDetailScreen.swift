//
//  HabitDetailScreen.swift
//  Habit
//
//  Created by TiniT on 29/4/26.
//

import SwiftUI

struct HabitDetailScreen: View {
    @Environment(HabitStore.self) private var habitStore
    let habitID: UUID

    var body: some View {
        Group {
            if let habit = habitStore.habit(id: habitID) {
                HabitDetailContent(habitID: habitID, habit: habit)
            } else {
                Text("No habit selected")
            }
        }
    }
}

struct HabitDetailContent: View {
    @Environment(HabitStore.self) private var habitStore
    @Environment(\.dismiss) private var dismiss
    let habitID: UUID
    @Bindable var habit: Habit
    @FocusState private var isFocused: Bool
    @State private var shouldDeleteOnDisappear = false

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
                        shouldDeleteOnDisappear = true
                        dismiss()
                    }
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .onDisappear {
            if shouldDeleteOnDisappear {
                habitStore.deleteHabit(id: habitID)
            }
        }
    }
}

#Preview {
    HabitDetailScreen(habitID: Habit.mock.id)
}
