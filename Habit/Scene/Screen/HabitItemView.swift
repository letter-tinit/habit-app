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

    @Binding var habit: Habit
    private let cornerRadius: CGFloat = 12.0
    var body: some View {
        let entry = habit.entry(for: Date())
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
                .scaleEffect(x: entry?.completionRatio ?? 0.0, y: 1, anchor: .leading)
            
            Button {
                habitStore.selectedHabit = habit
                router.push(.habitDetail)
            } label: {
                HStack {
                    Text(habit.emoji)
                        .padding(5)
                        .background()
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    Text(habit.name)
                        .font(.headline)
                        .fontDesign(.rounded)
                    
                    Spacer()
                }
            }
            .padding()
        }
        .overlay(alignment: .trailing) {
            Button {
//                if progress < 1 {
//                    baseAnimation {
//                        progress += 0.2
//                    }
//                }
            } label: {
                Image(systemName: "plus")
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
            }
            .padding(8)
            .buttonStyle(.plain)
            .glassEffect()
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
    }
}

#Preview {
    HabitItemView(habit: .constant(.mock))
}
