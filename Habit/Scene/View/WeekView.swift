//
//  WeekView.swift
//  Habit
//
//  Created by TiniT on 29/4/26.
//

import SwiftUI

struct WeekView: View {
    // MARK: - Enum
    enum DateState {
        case selected
        case unselected
        case unselectedToday
        
        init(isSelected: Bool, isToday: Bool) {
            switch (isSelected, isToday) {
            case (true, false), (true, true):
                self = .selected
            case (false, true):
                self = .unselectedToday
            case (false, false):
                self = .unselected
            }
        }
        
        var color: Color {
            switch self {
            case .selected:
                    .rosePink
            case .unselected:
                    .warmGray
            case .unselectedToday:
                    .black
            }
        }
    }
    
    @Environment(HabitStore.self) private var habitStore
    @State private var centerDate = Date()
    @State private var weekPage = 0

    private func calendar(weekStartsOnMonday: Bool) -> Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = weekStartsOnMonday ? 2 : 1
        return calendar
    }

    private func weekDates(for page: Int, weekStartsOnMonday: Bool) -> [Date] {
        let calendar = calendar(weekStartsOnMonday: weekStartsOnMonday)
        guard
            let pageDate = calendar.date(byAdding: .weekOfYear, value: page, to: centerDate),
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: pageDate)
        else {
            return []
        }

        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekInterval.start)
        }
    }

    private func moveWeek(by value: Int, weekStartsOnMonday: Bool) {
        let calendar = calendar(weekStartsOnMonday: weekStartsOnMonday)
        guard let date = calendar.date(byAdding: .weekOfYear, value: value, to: centerDate) else {
            return
        }

        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            centerDate = date
            weekPage = 0
        }

        baseAnimation {
            habitStore.didChangeSelecteDate(date)
        }
    }

    private func syncCenterDateIfNeeded(with date: Date) {
        guard
            weekPage == 0,
            !centerDate.isEqual(with: date)
        else {
            return
        }

        centerDate = date
    }
    
    private func weekRow(for page: Int, weekStartsOnMonday: Bool) -> some View {
        let dates = weekDates(for: page, weekStartsOnMonday: weekStartsOnMonday)
        return HStack {
            ForEach(Array(dates.enumerated()), id: \.element) { index, date in
                let isSelected = habitStore.isSelectedDay(date)
                let isToday = date.isToday()
                let dateState = DateState(isSelected: isSelected, isToday: isToday)
                let tintColor: Color = dateState.color
                let fontWeight: Font.Weight = isSelected ? .bold : .regular
                
                Button {
                    baseAnimation {
                        habitStore.didChangeSelecteDate(date)
                    }
                } label: {
                    VStack(spacing: 10) {
                        Text(date.toString(withFormat: .dayName))
                            .font(.caption)
                            .fontDesign(.rounded)
                            .fontWeight(fontWeight)

                        CircularWithTitleProgressView(
                            progress: habitStore.completionRatio(on: date),
                            title: date.toString(withFormat: .dayNo),
                            tintColor: tintColor,
                            fontWeight: fontWeight
                        )
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 10)
                    .foregroundStyle(tintColor)
                    .overlay {
                        Capsule()
                            .stroke(
                                tintColor,
                                lineWidth: dateState == .unselected ? 1 : 2
                            )
                    }
                    .shadow(
                        color: isSelected ? Color.rosePink.opacity(0.65) : .clear,
                        radius: 4,
                        y: 4
                    )
                    .scaleEffect(isSelected ? 1.1 : 1)
                    .padding(.bottom, 10)
                }
                
                if index < dates.count - 1 {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 3)
    }

    var body: some View {
        let weekStartsOnMonday = habitStore.weekStartsOnMonday
        
        TabView(selection: $weekPage) {
            ForEach(-1...1, id: \.self) { page in
                weekRow(for: page, weekStartsOnMonday: weekStartsOnMonday)
                    .tag(page)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 100)
        .onAppear {
            centerDate = habitStore.selectedDate
        }
        .onChange(of: weekPage) { _, newValue in
            guard newValue != 0 else { return }
            moveWeek(by: newValue, weekStartsOnMonday: weekStartsOnMonday)
        }
        .onChange(of: habitStore.selectedDate) { _, newValue in
            syncCenterDateIfNeeded(with: newValue)
        }
        .onChange(of: weekStartsOnMonday) {
            centerDate = habitStore.selectedDate
            weekPage = 0
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    WeekView()
}
