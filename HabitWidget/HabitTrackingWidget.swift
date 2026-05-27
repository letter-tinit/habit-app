//
//  HabitTrackingWidget.swift
//  HabitWidget
//
//  Created by Codex on 27/5/26.
//

import SwiftUI
import WidgetKit
import AppIntents

struct HabitTrackingWidget: Widget {
    let kind = "HabitTrackingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitTimelineProvider()) { entry in
            HabitTrackingWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today Habits")
        .description("Track today's habits without opening the app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HabitTimelineEntry: TimelineEntry {
    let date: Date
    let snapshot: HabitWidgetSnapshot
}

struct HabitTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitTimelineEntry {
        HabitTimelineEntry(
            date: Date(),
            snapshot: HabitWidgetSnapshot(
                date: Date(),
                habits: [
                    HabitWidgetItem(
                        id: UUID(),
                        name: "Write",
                        icon: "pencil",
                        colorHex: "#4ECDC4",
                        goalTypeRawValue: "todo",
                        goalCount: 1,
                        goalUnit: "times",
                        completedCount: 0,
                        currentStreak: 3,
                        scheduledWeekdays: Array(0...6)
                    )
                ]
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitTimelineEntry) -> Void) {
        completion(HabitTimelineEntry(date: Date(), snapshot: HabitWidgetStore.loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitTimelineEntry>) -> Void) {
        let entry = HabitTimelineEntry(date: Date(), snapshot: HabitWidgetStore.loadSnapshot())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct HabitTrackingWidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    let entry: HabitTimelineEntry

    private var habits: [HabitWidgetItem] {
        switch widgetFamily {
        case .systemSmall:
            Array(entry.snapshot.habits.prefix(3))
        default:
            Array(entry.snapshot.habits.prefix(5))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today")
                    .font(.headline)
                    .fontDesign(.rounded)

                Spacer()

                Text(completionText)
                    .font(.caption2.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }

            if habits.isEmpty {
                Spacer(minLength: 0)
                ContentUnavailableView(
                    "No Habits",
                    systemImage: "checkmark.circle",
                    description: Text("Open Habit to add one.")
                )
                .fontDesign(.rounded)
                Spacer(minLength: 0)
            } else {
                VStack(spacing: 7) {
                    ForEach(habits) { habit in
                        HabitWidgetRow(habit: habit)
                    }
                }
            }
        }
    }

    private var completionText: String {
        let completed = entry.snapshot.habits.filter(\.isCompleted).count
        return "\(completed)/\(entry.snapshot.habits.count)"
    }
}

private struct HabitWidgetRow: View {
    let habit: HabitWidgetItem

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: habit.icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: habit.colorHex))
                .frame(width: 22, height: 22)
                .background(Color.primary.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 1) {
                Text(habit.name)
                    .font(.caption.weight(.semibold))
                    .fontDesign(.rounded)
                    .lineLimit(1)

                Text(habit.progressText)
                    .font(.caption2)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if habit.isCompleted {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.caption.weight(.bold))
            } else {
                Button(intent: CompleteHabitIntent(habitID: habit.id, completedCount: habit.goalCount)) {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: habit.colorHex))
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview(as: .systemMedium) {
    HabitTrackingWidget()
} timeline: {
    HabitTimelineEntry(
        date: Date(),
        snapshot: HabitWidgetSnapshot(
            date: Date(),
            habits: [
                HabitWidgetItem(
                    id: UUID(),
                    name: "Write",
                    icon: "pencil",
                    colorHex: "#4ECDC4",
                    goalTypeRawValue: "todo",
                    goalCount: 1,
                    goalUnit: "times",
                    completedCount: 0,
                    currentStreak: 3,
                    scheduledWeekdays: Array(0...6)
                )
            ]
        )
    )
}
