//
//  CreateHabitScreen.swift
//  Habit
//
//  Created by TiniT on 15/5/26.
//

import SwiftUI
import SwiftData

struct CreateHabitScreen: View {
    @Environment(HabitStore.self) private var habitStore
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    
    @State private var screenTitle = "New Habit"
    @State private var name = "Habit Name"
    @State private var emoji = "⭐"
    @State private var habitDescription = ""
    @State private var colorHex = AppConstant.defaultColor
    @State private var frequency: HabitFrequency = .daily
    @State private var selectedDays: Set<Int> = Set(0...6)
    @State private var goalType: GoalType = .todo
    @State private var goalCountText = "1"
    @State private var goalUnit = "times"
    
    private let colorOptions = AppConstant.colorOptions
    
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var trimmedEmoji: String {
        emoji.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var trimmedGoalUnit: String {
        goalUnit.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var goalCount: Int {
        goalType == .todo ? 1 : Int(goalCountText) ?? 0
    }
    
    private var canSave: Bool {
        !trimmedName.isEmpty &&
        !trimmedEmoji.isEmpty &&
        goalCount > 0 &&
        !trimmedGoalUnit.isEmpty &&
        (frequency != .custom || !selectedDays.isEmpty)
    }
    
    var body: some View {
        BaseScreen($screenTitle) {
            AppScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    identitySection
                    scheduleSection
                    goalSection
                    styleSection
                    previewItem
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
        // MARK: - ToolBar
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    saveHabit()
                } label: {
                    Text("Save")
                        .fontWeight(canSave ? .bold : .regular)
                        .fontDesign(.rounded)
                }
                .disabled(!canSave)
            }
        }
        .animation(.snappy, value: goalType)
    }
    
    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Identity")
                .font(.headline)
                .fontDesign(.rounded)
            
            TextField("Habit name", text: $name)
                .textInputAutocapitalization(.words)
                .padding()
                .liquidGlassSurface(cornerRadius: 12, interactive: true)
            
            HStack(spacing: 12) {
                ZStack {
                    Button {
                        baseAnimation {
                            isFocused = true
                        }
                    } label: {
                        Text(emoji)
                            .font(.headline)
                    }
                    .aspectRatio(1, contentMode: .fill)
                    .padding()
                    .liquidGlassSurface(cornerRadius: 12, interactive: true)
                    
                    TextField("", text: $emoji)
                        .frame(width: 0, height: 0)
                        .focused($isFocused)
                        .opacity(0)
                        .keyboardType(.emoji)
                        .onChange(of: emoji) { _, newValue in
                            if let last = newValue.last, last.isEmoji {
                                emoji = String(last)
                            }
                        }
                }
                
                TextField("Description", text: $habitDescription)
                    .padding()
                    .liquidGlassSurface(cornerRadius: 12, interactive: true)
            }
        }
    }
    
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repeat")
                .font(.headline)
                .fontDesign(.rounded)
            
            Picker("Repeat", selection: $frequency) {
                Text("Daily").tag(HabitFrequency.daily)
                Text("Weekday").tag(HabitFrequency.weekday)
                Text("Weekend").tag(HabitFrequency.weekend)
                Text("Custom").tag(HabitFrequency.custom)
            }
            .pickerStyle(.menu)
            .onChange(of: frequency) { _, newValue in
                applyDefaultDays(for: newValue)
            }
            
            if frequency == .custom {
                HStack(spacing: 8) {
                    ForEach(habitStore.orderedWeekdays, id: \.self) { weekday in
                        Button {
                            toggleWeekday(weekday)
                        } label: {
                            Text(shortWeekdayName(for: weekday))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .fontDesign(.rounded)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .foregroundStyle(selectedDays.contains(weekday) ? .white : .primary)
                                .background(selectedDays.contains(weekday) ? Color.rosePink.opacity(0.68) : Color.primary.opacity(0.06))
                                .liquidGlassSurface(cornerRadius: 8, interactive: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal")
                .font(.headline)
                .fontDesign(.rounded)
            
            Picker("Goal type", selection: $goalType) {
                Text("Todo").tag(GoalType.todo)
                Text("Count").tag(GoalType.count)
            }
            .pickerStyle(.segmented)
            .onChange(of: goalType) { _, newValue in
                if newValue == .todo {
                    goalCountText = "1"
                    goalUnit = "times"
                }
            }
            
            if goalType == .count {
                HStack(spacing: 12) {
                    TextField("Target", text: $goalCountText)
                        .keyboardType(.numberPad)
                        .disabled(goalType == .todo)
                        .padding()
                        .liquidGlassSurface(cornerRadius: 12, interactive: true)
                    
                    TextField("Unit", text: $goalUnit)
                        .padding()
                        .liquidGlassSurface(cornerRadius: 12, interactive: true)
                }
                .transition(.opacity)
            }
        }
    }
    
    private var styleSection: some View {
        HStack(spacing: 10) {
            ForEach(colorOptions, id: \.self) { hex in
                Button {
                    colorHex = hex
                } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 34, height: 34)
                        .overlay {
                            Circle()
                                .stroke(colorHex == hex ? Color.primary : Color.clear, lineWidth: 2)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        
    }
    
    private var previewItem: some View {
        let emptyHabit = Habit(
            name: trimmedName,
            emoji: trimmedEmoji,
            description: habitDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: colorHex,
            frequency: frequency,
            targetDaysOfWeek: Array(selectedDays).sorted(),
            goalType: goalType,
            goalCount: goalCount,
            goalUnit: trimmedGoalUnit,
        )
        
        let entry = HabitEntry(
            date: Date(),
            completedCount: 0,
            note: "Read 20 pages and practiced SwiftUI"
        )
        
        emptyHabit.entries.append(entry)
        
        let halfHabit = Habit(
            name: trimmedName,
            emoji: trimmedEmoji,
            description: habitDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: colorHex,
            frequency: frequency,
            targetDaysOfWeek: Array(selectedDays).sorted(),
            goalType: goalType,
            goalCount: goalCount,
            goalUnit: trimmedGoalUnit,
        )
        
        let halfEntry = HabitEntry(
            date: Date(),
            completedCount: goalCount / 2,
            note: "Read 20 pages and practiced SwiftUI"
        )
        
        halfHabit.entries.append(halfEntry)
        
        let doneHabit = Habit(
            name: trimmedName,
            emoji: trimmedEmoji,
            description: habitDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: colorHex,
            frequency: frequency,
            targetDaysOfWeek: Array(selectedDays).sorted(),
            goalType: goalType,
            goalCount: goalCount,
            goalUnit: trimmedGoalUnit,
        )
        
        let doneEntry = HabitEntry(
            date: Date(),
            completedCount: goalCount,
            note: "Read 20 pages and practiced SwiftUI"
        )
        
        doneHabit.entries.append(doneEntry)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .fontDesign(.rounded)
            
            Text("Untrack")
                .font(.subheadline)
                .fontDesign(.rounded)
            HabitItemView(habit: emptyHabit, selectedDate: Date())
            
            if goalType == .count && goalCount > 1 {
                Text("In Progress")
                    .font(.subheadline)
                    .fontDesign(.rounded)
                HabitItemView(habit: halfHabit, selectedDate: Date())
            }
            
            Text("Done")
                .font(.subheadline)
                .fontDesign(.rounded)
            HabitItemView(habit: doneHabit, selectedDate: Date())
        }
    }
    
    private func saveHabit() {
        guard canSave else { return }
        
        let habit = Habit(
            name: trimmedName,
            emoji: trimmedEmoji,
            description: habitDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: colorHex,
            frequency: frequency,
            targetDaysOfWeek: Array(selectedDays).sorted(),
            goalType: goalType,
            goalCount: goalCount,
            goalUnit: trimmedGoalUnit
        )
        
        habitStore.addHabit(habit)
        dismiss()
    }
    
    private func applyDefaultDays(for frequency: HabitFrequency) {
        switch frequency {
        case .daily:
            selectedDays = Set(0...6)
        case .weekday:
            selectedDays = [1, 2, 3, 4, 5]
        case .weekend:
            selectedDays = [0, 6]
        case .custom:
            selectedDays = []
        }
    }
    
    private func toggleWeekday(_ weekday: Int) {
        if selectedDays.contains(weekday) {
            selectedDays.remove(weekday)
        } else {
            selectedDays.insert(weekday)
        }
    }
    
    private func shortWeekdayName(for weekday: Int) -> String {
        switch weekday {
        case 0: "Sun"
        case 1: "Mon"
        case 2: "Tue"
        case 3: "Wed"
        case 4: "Thu"
        case 5: "Fri"
        case 6: "Sat"
        default: ""
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Habit.self, HabitEntry.self, HabitReminder.self, UserProfile.self,
        configurations: config
    )
    
    NavigationStack {
        CreateHabitScreen()
            .modelContainer(container)
            .environment(HabitStore(modelContext: container.mainContext))
    }
}
