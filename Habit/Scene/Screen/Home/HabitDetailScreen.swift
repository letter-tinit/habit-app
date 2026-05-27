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
    @State private var showEditHabit = false
    @State private var showsArchiveConfirmation = false
    @State private var showsDeleteConfirmation = false

    var body: some View {
        BaseScreen($habit.name) {
            AppScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Button {
                            baseAnimation {
                                isFocused = true
                            }
                        } label: {
                            Image(module: habit.icon)
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
                        detailRow(title: "Reminders", value: reminderTitle)
                        Divider().opacity(0.28)
                        detailRow(title: "Goal", value: goalTitle)
                        Divider().opacity(0.28)
                        detailRow(title: "Current streak", value: "\(habit.currentStreak)")
                        Divider().opacity(0.28)
                        detailRow(title: "Best streak", value: "\(habit.longestStreak)")
                        if let archivedAt = habit.archivedAt {
                            Divider().opacity(0.28)
                            detailRow(
                                title: "Archived on",
                                value: archivedAt.toString(withFormat: .custom("MMM d, yyyy"))
                            )
                        }
                    }
                    .padding(.horizontal)
                    .liquidGlassSurface(cornerRadius: 20)
                }
                .padding()
            }
        }
        // MARK: - ToolBar
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditHabit = true
                } label: {
                    Image(module: "pencil")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showsArchiveConfirmation = true
                } label: {
                    Image(module: habit.isArchived ? "tray.and.arrow.up" : "archivebox")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showsDeleteConfirmation = true
                } label: {
                    Image(module: "trash")
                }
            }
        }
        .confirmationDialog(
            habit.isArchived ? "Unarchive habit?" : "Archive habit?",
            isPresented: $showsArchiveConfirmation,
            titleVisibility: .visible
        ) {
            Button(habit.isArchived ? "Unarchive Habit" : "Archive Habit", role: habit.isArchived ? nil : .destructive) {
                archiveHabit()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            if habit.isArchived {
                Text("This habit will return to your active habit list.")
            } else {
                Text("This habit will be hidden from future days, but existing history will be kept.")
            }
        }
        .confirmationDialog(
            "Delete habit?",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Habit", role: .destructive) {
                deleteHabit()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes the habit, entries, reminders, and history. This cannot be undone.")
        }
        .sheet(isPresented: $showEditHabit) {
            NavigationStack {
                CreateHabitScreen(habit: habit)
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

    private var reminderTitle: String {
        let enabledReminders = habit.reminders
            .filter(\.isEnabled)
            .sorted { $0.time < $1.time }

        guard !enabledReminders.isEmpty else {
            return "None"
        }

        return enabledReminders
            .map { $0.time.toString(withFormat: .custom("HH:mm")) }
            .joined(separator: ", ")
    }

    private func archiveHabit() {
        if habit.isArchived {
            habitStore.unarchiveHabit(habit)
        } else {
            habitStore.archiveHabit(habit)
        }
    }

    private func deleteHabit() {
        if habitStore.deleteHabit(id: habitID) {
            dismiss()
        }
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
