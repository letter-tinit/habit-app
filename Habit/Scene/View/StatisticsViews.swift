//
//  StatisticsViews.swift
//  Habit
//
//  Created by TiniT on 21/5/26.
//

import SwiftUI

enum StatisticsScope: String, CaseIterable {
    case month = "Month"
    case year = "Year"
}

struct StatisticsOverviewView: View {
    @Environment(HabitStore.self) private var habitStore
    @Binding var scope: StatisticsScope

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Statistics")
                    .font(.headline)
                    .fontDesign(.rounded)

                Spacer()

                Picker("Statistics", selection: $scope) {
                    ForEach(StatisticsScope.allCases, id: \.self) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            switch scope {
            case .month:
                MonthlyStatisticsView(date: habitStore.selectedDate)
            case .year:
                YearlyStatisticsView(date: habitStore.selectedDate)
            }
        }
        .padding()
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
    }
}

struct MonthlyStatisticsView: View {
    @Environment(HabitStore.self) private var habitStore
    let date: Date

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    private var monthTitle: String {
        date.toString(withFormat: .custom("MMMM yyyy"))
    }

    private var paddedDates: [Date?] {
        guard let firstDate = habitStore.monthDates(containing: date).first else {
            return []
        }

        let weekday = AppCalendar.current.component(.weekday, from: firstDate) - 1
        let leadingEmptyDays = habitStore.orderedWeekdays.firstIndex(of: weekday) ?? 0

        return Array(repeating: nil, count: leadingEmptyDays) + habitStore.monthDates(containing: date).map(Optional.some)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                CircularWithTitleProgressView(
                    progress: habitStore.completionRatioForMonth(containing: date),
                    title: "\(Int(habitStore.completionRatioForMonth(containing: date) * 100))%",
                    size: 52,
                    tintColor: .rosePink,
                    fontWeight: .bold
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(monthTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)

                    Text("Monthly progress")
                        .font(.caption)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(habitStore.orderedWeekdays, id: \.self) { weekday in
                    Text(shortWeekdayName(for: weekday))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(paddedDates.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let progress = habitStore.completionRatio(on: date)
                        let isSelected = habitStore.isSelectedDay(date)

                        Button {
                            baseAnimation {
                                habitStore.didChangeSelecteDate(date)
                            }
                        } label: {
                            CircularWithTitleProgressView(
                                progress: progress,
                                title: date.toString(withFormat: .dayNo),
                                size: 34,
                                tintColor: tintColor(for: progress),
                                fontWeight: isSelected ? .bold : .regular
                            )
                            .foregroundStyle(isSelected ? Color.rosePink : .primary)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    } else {
                        Color.clear
                            .frame(width: 34, height: 34)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func tintColor(for progress: Double) -> Color {
        switch progress {
        case 0:
            .warmGray.opacity(0.35)
        case 0..<0.34:
            .sunsetOrange
        case 0.34..<0.67:
            .goldenYellow
        default:
            .emeraldGreen
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

struct YearlyStatisticsView: View {
    @Environment(HabitStore.self) private var habitStore
    let date: Date

    private let cellSize: CGFloat = 10

    private var yearTitle: String {
        date.toString(withFormat: .custom("yyyy"))
    }

    private var weeks: [[Date]] {
        let calendar = AppCalendar.current
        guard
            let yearInterval = calendar.dateInterval(of: .year, for: date),
            let startWeek = calendar.dateInterval(of: .weekOfYear, for: yearInterval.start),
            let lastDay = calendar.date(byAdding: .day, value: -1, to: yearInterval.end),
            let endWeek = calendar.dateInterval(of: .weekOfYear, for: lastDay)
        else {
            return []
        }

        var weeks: [[Date]] = []
        var currentDate = calendar.startOfDay(for: startWeek.start)

        while currentDate < endWeek.end {
            let week = (0..<7).compactMap {
                calendar.date(byAdding: .day, value: $0, to: currentDate)
            }
            weeks.append(week)

            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) else {
                break
            }

            currentDate = nextWeek
        }

        return weeks
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                CircularWithTitleProgressView(
                    progress: habitStore.completionRatioForYear(containing: date),
                    title: "\(Int(habitStore.completionRatioForYear(containing: date) * 100))%",
                    size: 52,
                    tintColor: .emeraldGreen,
                    fontWeight: .bold
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(yearTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)

                    Text("Yearly progress")
                        .font(.caption)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                }
            }

            AppScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .trailing, spacing: 4) {
                        ForEach(habitStore.orderedWeekdays, id: \.self) { weekday in
                            Text(shortWeekdayName(for: weekday))
                                .font(.system(size: 8, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .frame(width: 18, height: cellSize)
                        }
                    }

                    HStack(alignment: .top, spacing: 4) {
                        ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                            VStack(spacing: 4) {
                                ForEach(week, id: \.self) { date in
                                    contributionCell(for: date)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func contributionCell(for date: Date) -> some View {
        let calendar = AppCalendar.current
        let isCurrentYear = calendar.isDate(date, equalTo: self.date, toGranularity: .year)
        let progress = habitStore.completionRatio(on: date)

        return RoundedRectangle(cornerRadius: 2)
            .fill(isCurrentYear ? blockColor(for: progress) : Color.clear)
            .frame(width: cellSize, height: cellSize)
            .overlay {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.black.opacity(isCurrentYear ? 0.08 : 0), lineWidth: 0.5)
            }
    }

    private func blockColor(for progress: Double) -> Color {
        switch progress {
        case 0:
            .white.opacity(0.55)
        case 0..<0.25:
            .rosePink.opacity(0.55)
        case 0.25..<0.5:
            .sunsetOrange.opacity(0.75)
        case 0.5..<0.75:
            .goldenYellow.opacity(0.85)
        default:
            .emeraldGreen
        }
    }

    private func shortWeekdayName(for weekday: Int) -> String {
        switch weekday {
        case 0: "S"
        case 1: "M"
        case 2: "T"
        case 3: "W"
        case 4: "T"
        case 5: "F"
        case 6: "S"
        default: ""
        }
    }
}
