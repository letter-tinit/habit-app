//
//  WeekView.swift
//  Habit
//
//  Created by TiniT on 29/4/26.
//

import SwiftUI

struct WeekView: View {
    @Environment(HabitStore.self) private var habitStore
    private let calendar = Calendar.current

    private var last7Days: [Date] {
        (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: Date())
        }
        .sorted()
    }
    
    
    // MARK: - Function
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEEE"
        return formatter.string(from: date)
    }

    private func dayNo(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    var body: some View {
        HStack(spacing: 20) {
            ForEach(last7Days, id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: habitStore.selectedDate)
                
                Button {
                    baseAnimation {
                        habitStore.didChangeSelecteDate(date)
                    }
                } label: {
                    VStack(spacing: 10) {
                        Text(dayName(for: date))
                            .font(.caption)
                            .fontDesign(.rounded)
                        
                        CircularWithTitleProgressView(progress: 0.5, title: dayNo(for: date))
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(contentMode: .fill)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .stroke(lineWidth: isSelected ? 1 : 0)
                            .foregroundStyle(.gray)
                    )
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    WeekView()
}
