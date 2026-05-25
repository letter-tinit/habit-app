//
//  HabitItemView.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import SwiftUI

struct HabitItemView: View {
    enum Action {
        case tapped
        case progressChanged(Int)
    }

    // MARK: - Input Param
    private let name: String
    private let icon: String
    private let colorHex: String
    private let gradient: LinearGradient
    private let goalType: GoalType
    private let goalCount: Int
    private let goalUnit: String
    private let completedCount: Int
    private let completionRatio: Double
    private let currentStreak: Int
    private let longestStreak: Int
    private let lastCompleteStreak: Date?

    // MARK: - UI State
    private let cornerRadius: CGFloat = 12.0
    @State private var showNumberPad = false

    // MARK: - Callback
    var handleAction: ((Action) -> Void) = { _ in }

    init(
        habit: Habit,
        selectedDate: Date,
        handleAction: @escaping (Action) -> Void = { _ in }
    ) {
        let entry = habit.entry(for: selectedDate)
        self.name = habit.name
        self.icon = habit.icon
        self.colorHex = habit.colorHex
        self.gradient = habit.gradient
        self.goalType = habit.goalType
        self.goalCount = habit.goalCount
        self.goalUnit = habit.goalUnit
        self.completedCount = entry?.completedCount ?? 0
        self.completionRatio = entry?.completionRatio ?? 0
        self.handleAction = handleAction
        self.currentStreak = habit.currentStreak
        self.longestStreak = habit.longestStreak
        self.lastCompleteStreak = habit.lastCompletedDate
    }

    var body: some View {
//        isCompleted = completionRatio > 1.0
        ZStack {
            // MARK: - PROGRESS LAYER
            gradient
                .opacity(0.6)
                .clipShape(
                    .rect(
                        topLeadingRadius: cornerRadius,
                        bottomLeadingRadius: cornerRadius,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                )
                .scaleEffect(x: completionRatio, y: 1, anchor: .leading)

            // MARK: - HABIT INFOR
            HStack {
                Image(systemName: icon)

                VStack(alignment: .leading) {
                    Text(name)
                        .font(.headline)
                        .fontDesign(.rounded)
                    
                    Group {
                        if goalType == .count {
                            Text("\(completedCount)/\(goalCount) \(goalUnit)")
                                .padding(.horizontal, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.primary.opacity(0.06))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 3)
                                                .stroke(Color.primary.opacity(0.20), lineWidth: 0.4)
                                        }
                                )
                        } else {
                            let isCompleted = completionRatio >= 1
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isCompleted ? Color.green : Color.secondary)
                        }
                    }
                    .font(.caption2)
                    .fontDesign(.rounded)
                    .fontWeight(.regular)
                }

                Spacer()
            }
            .padding()
        }
        // MARK: - PLUS BUTTON
        .overlay(alignment: .trailing) {
            Button {
                baseAnimation {
                    Haptic.impact(.heavy)
                    if goalType == .todo {
                        handleAction(.progressChanged(1))
                    } else {
                        showNumberPad = true
                    }
                }
            } label: {
                Image(systemName: goalType == .todo ? "checkmark" : "plus")
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
            }
            .padding(8)
            .buttonStyle(.plain)
            .glassEffect(
                .regular,
                in: .circle
            )
            .padding(.horizontal, 10)
            .shadow(color: .black.opacity(0.3), radius: 1)
            .opacity(completionRatio == 1 ? 0 : 1)
        }
        // MARK: - ITEM STYLE
        .mask {
            RoundedRectangle(cornerRadius: cornerRadius)
        }
        .liquidGlassSurface(cornerRadius: cornerRadius, interactive: true)
        // MARK: - Action
        .sheet(isPresented: $showNumberPad) {
            ZStack {
                Color.primary.opacity(0.02).ignoresSafeArea()

                NumberPadSheet(
                    habitName: name,
                    unit: goalUnit,
                    current: completedCount,
                    goal: goalCount
                ) { value in
                    baseAnimation {
                        let newCount = completedCount + value
                        Haptic.impact()
                        handleAction(.progressChanged(newCount))
                    }
                }
            }
            .presentationBackground(.ultraThinMaterial)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onTapGesture {
            Haptic.selection()
            handleAction(.tapped)
        }
    }
}

// MARK: - NumberPadSheet
struct NumberPadSheet: View {
    let habitName: String
    let unit: String
    let current: Int
    let goal: Int
    let onConfirm: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var input: String = ""

    private let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["C", "0", "⌫"]
    ]

    private var parsedValue: Int { Int(input) ?? 0 }

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            // Display
            Text(input.isEmpty ? "0" : input)
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .contentTransition(.numericText())
                .animation(.snappy, value: input)

            // Number Pad Grid
            VStack(spacing: 10) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { key in
                            NumberPadKey(label: key) {
                                handleKey(key)
                            }
                        }
                    }
                }
            }

            // Confirm Button
            Button {
                let value = parsedValue
                if value > 0 {
                    onConfirm(value)
                }
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.primary)
                    .liquidGlassSurface(cornerRadius: 14, interactive: true)
                    .animation(.snappy, value: parsedValue)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .overlay(alignment: .topTrailing) {
            Text(unit)
                .font(.caption)
                .fontDesign(.rounded)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(lineWidth: 0.5)
                )
                .padding(.trailing, 30)
        }
    }

    private func handleKey(_ key: String) {
        switch key {
        case "C":
            input = ""
        case "⌫":
            if !input.isEmpty { input.removeLast() }
        default:
            // Prevent leading zeros and cap at 4 digits
            if input == "0" { input = "" }
            if input.count < 4 { input += key }
        }
    }
}

// MARK: - NumberPadKey

struct NumberPadKey: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.title2)
                .fontWeight(.medium)
                .fontDesign(.rounded)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .liquidGlassSurface(cornerRadius: 12, interactive: true)
        }
        .buttonStyle(.plain)
    }
}
