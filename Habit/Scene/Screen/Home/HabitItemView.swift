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
    private let emoji: String
    private let colorHex: String
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
        self.emoji = habit.emoji
        self.colorHex = habit.colorHex
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
        ZStack {
            // MARK: - PROGRESS LAYER
            Color.init(hex: colorHex).opacity(0.35)
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
                Text(emoji)
                    .padding(5)
                    .background()
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.headline)
                        .fontDesign(.rounded)
                    
                    if goalType == .count {
                        Text("\(completedCount)/\(goalCount) \(goalUnit)")
                            .font(.caption2)
                            .fontDesign(.rounded)
                            .fontWeight(.regular)
                            .padding(.horizontal, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(lineWidth: 0.4)
                            )
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        // MARK: - PLUS BUTTON
        .overlay(alignment: .trailing) {
            Button {
                baseAnimation {
                    if goalType == .todo {
                        Haptic.impact(.heavy)
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
                .regular
                    .interactive(),
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
        .glassEffect(
            .regular
                .interactive(),
            in: .rect(cornerRadius: cornerRadius)
        )
        // MARK: - Action
        .sheet(isPresented: $showNumberPad) {
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
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onTapGesture {
            Haptic.selection()
            handleAction(.tapped)
        }
    }
}

#Preview {
    HabitItemView(habit: .mock, selectedDate: Date())
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
                .overlay(alignment: .bottomTrailing) {
                    Text(unit)
                        .font(.caption)
                        .fontDesign(.rounded)
                }
            
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
                    .background(Color.secondary.opacity(0.2))
                    .foregroundStyle(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .animation(.snappy, value: parsedValue)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
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
                .background(.quaternary.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
