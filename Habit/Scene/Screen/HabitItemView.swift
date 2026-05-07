//
//  HabitItemView.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import SwiftUI

struct HabitItemView: View {
    @Environment(HomeRouter.self) private var router
    @Environment(HabitStore.self) private var habitStore

    @State private var showNumberPad = false
    @Binding var habit: Habit
    private let cornerRadius: CGFloat = 12.0
    var body: some View {
        if let entry = habit.entry(for: habitStore.selectedDate) {
            ZStack {
                Color.init(hex: habit.colorHex).opacity(0.35)
                    .clipShape(
                        .rect(
                            topLeadingRadius: cornerRadius,
                            bottomLeadingRadius: cornerRadius,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0
                        )
                    )
                    .scaleEffect(x: entry.completionRatio, y: 1, anchor: .leading)
                
                Button {
                    logDebug("Select habit")
                    habitStore.selectedHabit = habit
                    router.push(.habitDetail)
                } label: {
                    HStack {
                        Text(habit.emoji)
                            .padding(5)
                            .background()
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        VStack(alignment: .leading) {
                            Text(habit.name)
                                .font(.headline)
                                .fontDesign(.rounded)
                            
                            Text("\(entry.completedCount)/\(habit.goalCount) \(habit.goalUnit)")
                                .font(.caption2)
                                .fontDesign(.rounded)
                                .fontWeight(.regular)
                                .padding(.horizontal, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(lineWidth: 0.4)
                                )
                        }
                        
                        Spacer()
                    }
                }
                .padding()
            }
            .overlay(alignment: .trailing) {
                Button {
                    logDebug("plus")
                    baseAnimation {
                        showNumberPad = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                }
                .padding(8)
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(weight: .medium), trigger: showNumberPad)
                .glassEffect(
                    .regular
                        .interactive(),
                    in: .circle
                )
                .padding(.horizontal, 10)
                .shadow(color: .black.opacity(0.3), radius: 1)
                //            .opacity(progress == 1 ? 0 : 1)
            }
            .mask {
                RoundedRectangle(cornerRadius: cornerRadius)
            }
            .glassEffect(
                .regular
                    .interactive(),
                in: .rect(cornerRadius: cornerRadius)
            )
            .sheet(isPresented: $showNumberPad) {
                NumberPadSheet(
                    habitName: habit.name,
                    unit: habit.goalUnit,
                    current: entry.completedCount,
                    goal: habit.goalCount
                ) { value in
                    baseAnimation {
                        entry.completedCount += value
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        } else {
            EmptyView()
        }
    }
}

#Preview {
    HabitItemView(habit: .constant(.mock))
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
//                .frame(maxWidth: .infinity)
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
