//
//  CreateHabitScreen.swift
//  Habit
//
//  Created by TiniT on 15/5/26.
//

import SwiftUI
import SwiftData

struct CreateHabitScreen: View {
    private enum Field {
        case habitName
    }

    @Environment(HabitStore.self) private var habitStore
    @Environment(\.dismiss) private var dismiss

    private let habitToEdit: Habit?

    @State private var screenTitle: String
    @State private var name: String
    @State private var icon: String
    @State private var habitDescription: String
    @State private var colorHex: String
    @State private var frequency: HabitFrequency
    @State private var selectedDays: Set<Int>
    @State private var goalType: GoalType
    @State private var goalCountText: String
    @State private var goalUnit: String
    @State private var showSymbolPicker = false
    @State private var hasClearedDefaultHabitName = false
    @FocusState private var focusedField: Field?

    private let colorOptions = AppConstant.colorOptions

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedGoalUnit: String {
        goalUnit.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var goalCount: Int {
        goalType == .todo ? 1 : Int(goalCountText) ?? 0
    }

    private var isEditing: Bool {
        habitToEdit != nil
    }

    private var canSave: Bool {
        !trimmedName.isEmpty &&
        goalCount > 0 &&
        !trimmedGoalUnit.isEmpty &&
        (frequency != .custom || !selectedDays.isEmpty)
    }

    init(habit: Habit? = nil) {
        habitToEdit = habit
        _screenTitle = State(initialValue: habit == nil ? "New Habit" : "Edit Habit")
        _name = State(initialValue: habit?.name ?? "Habit Name")
        _icon = State(initialValue: habit?.icon ?? "star.fill")
        _habitDescription = State(initialValue: habit?.habitDescription ?? "")
        _colorHex = State(initialValue: habit?.colorHex ?? AppConstant.defaultColor)
        _frequency = State(initialValue: habit?.frequency ?? .daily)
        _selectedDays = State(initialValue: Set(habit?.targetDaysOfWeek ?? Array(0...6)))
        _goalType = State(initialValue: habit?.goalType ?? .count)
        _goalCountText = State(initialValue: String(habit?.goalCount ?? 1))
        _goalUnit = State(initialValue: habit?.goalUnit ?? "times")
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
        .sheet(isPresented: $showSymbolPicker) {
            SymbolPickerSheet(selectedSymbol: $icon)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Identity")
                .font(.headline)
                .fontDesign(.rounded)

            TextField("Habit name", text: $name)
                .focused($focusedField, equals: .habitName)
                .textInputAutocapitalization(.words)
                .padding()
                .liquidGlassSurface(cornerRadius: 12, interactive: true)
                .onChange(of: focusedField) { _, newValue in
                    clearDefaultHabitNameIfNeeded(isFocused: newValue == .habitName)
                }

            HStack(spacing: 12) {
                Button {
                    baseAnimation {
                        showSymbolPicker = true
                    }
                } label: {
                    Image(systemName: icon)
                        .resizable()
                        .padding()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundStyle(Color.init(hex: colorHex))
                }
                .liquidGlassSurface(cornerRadius: 12, interactive: true)

                TextField("Description", text: $habitDescription)
                    .frame(height: 60)
                    .padding(.horizontal)
                    .liquidGlassSurface(cornerRadius: 12, interactive: true)
            }
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Repeat")
                .font(.headline)
                .fontDesign(.rounded)

            Picker("Repeat", selection: $frequency) {
                Text("Daily").tag(HabitFrequency.daily)
                Text("Weekday").tag(HabitFrequency.weekday)
                Text("Weekend").tag(HabitFrequency.weekend)
                Text("Custom").tag(HabitFrequency.custom)
            }
            .pickerStyle(.segmented)
            .onChange(of: frequency) { _, newValue in
                applyDefaultDays(for: newValue)
            }
            .disabled(isEditing)

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
                            .frame(height: 32)
                            .foregroundStyle(selectedDays.contains(weekday) ? .white : .primary)
                            .background(
                                selectedDays.contains(weekday)
                                ? Color.cyan.opacity(0.48)
                                : Color.primary.opacity(0.06)
                            )
                            . mask {
                                RoundedRectangle(cornerRadius: 8)
                            }
                            .liquidGlassSurface(cornerRadius: 8, interactive: true)
                    }
                    .buttonStyle(.plain)
                    .disabled(isEditing)
                }
            }

            if isEditing {
                Text("Repeat settings are locked to keep existing statistics stable.")
                    .font(.footnote)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal")
                .font(.headline)
                .fontDesign(.rounded)

            Picker("Goal type", selection: $goalType) {
                Text("Count").tag(GoalType.count)
                Text("Todo").tag(GoalType.todo)
            }
            .pickerStyle(.segmented)
            .onChange(of: goalType) { _, newValue in
                if newValue == .todo {
                    goalCountText = "1"
                    goalUnit = "times"
                }
            }
            .disabled(isEditing)

            if goalType == .count {
                HStack(spacing: 12) {
                    TextField("Target", text: $goalCountText)
                        .keyboardType(.numberPad)
                        .disabled(goalType == .todo || isEditing)
                        .padding()
                        .liquidGlassSurface(cornerRadius: 12, interactive: true)

                    TextField("Unit", text: $goalUnit)
                        .disabled(isEditing)
                        .padding()
                        .liquidGlassSurface(cornerRadius: 12, interactive: true)
                }
                .transition(.opacity)
            }

            if isEditing {
                Text("Goal settings are locked to keep completion history stable.")
                    .font(.footnote)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Style")
                .font(.headline)
                .fontDesign(.rounded)

            ScrollView(.horizontal) {
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
                        .padding(2)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var previewItem: some View {
        let emptyHabit = Habit(
            name: trimmedName,
            description: habitDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: icon,
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
            description: habitDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: icon,
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
            description: habitDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: icon,
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

        if let habitToEdit {
            habitStore.updateHabit(
                habitToEdit,
                name: trimmedName,
                description: habitDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: icon,
                colorHex: colorHex,
                frequency: habitToEdit.frequency,
                targetDaysOfWeek: habitToEdit.targetDaysOfWeek,
                goalType: habitToEdit.goalType,
                goalCount: habitToEdit.goalCount,
                goalUnit: habitToEdit.goalUnit
            )
        } else {
            let habit = Habit(
                name: trimmedName,
                description: habitDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: icon,
                colorHex: colorHex,
                frequency: frequency,
                targetDaysOfWeek: Array(selectedDays).sorted(),
                goalType: goalType,
                goalCount: goalCount,
                goalUnit: trimmedGoalUnit
            )

            habitStore.addHabit(habit)
        }

        dismiss()
    }

    private func clearDefaultHabitNameIfNeeded(isFocused: Bool) {
        guard isFocused,
              !isEditing,
              !hasClearedDefaultHabitName,
              name == "Habit Name"
        else {
            return
        }

        name = ""
        hasClearedDefaultHabitName = true
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

private struct SymbolPickerSheet: View {
    @Binding var selectedSymbol: String
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 56), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Symbol")
                .font(.headline)
                .fontDesign(.rounded)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(AppConstant.habitSymbolOptions, id: \.self) { symbol in
                        Button {
                            selectedSymbol = symbol
                            dismiss()
                        } label: {
                            Image(systemName: symbol)
                                .font(.title3)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .foregroundStyle(selectedSymbol == symbol ? .white : .primary)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedSymbol == symbol ? Color.cyan : Color.primary.opacity(0.06))
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(symbol)
                    }
                }
            }
        }
        .padding(20)
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
