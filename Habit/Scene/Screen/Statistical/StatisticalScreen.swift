//
//  StatisticalScreen.swift
//  Habit
//
//  Created by TiniT on 21/5/26.
//

import SwiftUI

struct StatisticalScreen: View {
    @Environment(HabitStore.self) private var habitStore
    @State private var statisticsScope: StatisticsScope = .month
    @State private var statisticsDate: Date = Date()
    @State private var title: String = "STATISTICAL"

    var body: some View {
        BaseScreen($title, backgroundType: .mint) {
            if habitStore.habits.isEmpty {
                ContentUnavailableView(
                    "No Habits",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Create a habit to view statistics.")
                )
            } else {
                VStack(spacing: 14) {
                    StatisticsTableHeader(
                        scope: $statisticsScope,
                        date: $statisticsDate
                    )
                    .padding(.horizontal)
                    .padding(.top, 14)

                    AppScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(habitStore.habits, id: \.id) { habit in
                                StatisticsOverviewView(
                                    habit: habit,
                                    scope: statisticsScope,
                                    date: statisticsDate,
                                    usesSimplifiedMode: habitStore.usesCompactStatisticsView
                                )
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptic.selection()
                    habitStore.usesCompactStatisticsView.toggle()
                } label: {
                    Image(systemName: habitStore.usesCompactStatisticsView ? "rectangle.expand.vertical" : "rectangle.compress.vertical")
                }
            }
        }
    }
}

#Preview {
    StatisticalScreen()
}
