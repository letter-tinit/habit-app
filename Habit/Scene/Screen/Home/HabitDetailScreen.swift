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
            AppScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Button {
                            baseAnimation {
                                isFocused = true
                            }
                        } label: {
                            Text(habit.emoji)
                                .font(.system(size: 34))
                                .frame(width: 72, height: 72)
                                .liquidGlassSurface(cornerRadius: 24, interactive: true)
                        }
                        .buttonStyle(.plain)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(habit.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .fontDesign(.rounded)
                            
                            Text(habit.habitDescription.isEmpty ? "No description" : habit.habitDescription)
                                .font(.subheadline)
                                .fontDesign(.rounded)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .padding()
                    .liquidGlassSurface(cornerRadius: 24)
                    
                    VStack(spacing: 0) {
                        detailRow(title: "Repeat", value: repeatTitle)
                        Divider().opacity(0.28)
                        detailRow(title: "Goal", value: goalTitle)
                        Divider().opacity(0.28)
                        detailRow(title: "Current streak", value: "\(habit.currentStreak)")
                        Divider().opacity(0.28)
                        detailRow(title: "Best streak", value: "\(habit.longestStreak)")
                    }
                    .padding(.horizontal)
                    .liquidGlassSurface(cornerRadius: 20)
                    
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
                }
                .padding()
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
    
    private var repeatTitle: String {
        switch habit.frequency {
        case .daily: "Daily"
        case .weekday: "Weekdays"
        case .weekend: "Weekends"
        case .custom: "Custom"
        }
    }
    
    private var goalTitle: String {
        habit.goalType == .todo ? "Complete once" : "\(habit.goalCount) \(habit.goalUnit)"
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
        }
        .frame(minHeight: 48)
    }
}

#Preview {
    HabitDetailScreen(habitID: Habit.mock.id)
}
