//
//  ProfileScreen.swift
//  Habit
//
//  Created by TiniT on 19/5/26.
//

import SwiftUI
import SwiftData

struct ProfileScreen: View {
    @Environment(HabitStore.self) private var habitStore
    @State private var title = "Profile"

    var body: some View {
        BaseScreen($title, backgroundType: .cyan) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    settingsSection
                    frequencyPreviewSection
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            habitStore.fetchUserProfile()
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Preferences")
                .font(.headline)
                .fontDesign(.rounded)

            Toggle("Start week on Monday", isOn: Binding(
                get: { habitStore.weekStartsOnMonday },
                set: { habitStore.updateWeekStartsOnMonday($0) }
            ))
            .font(.body)
            .fontDesign(.rounded)
            .padding()
            .liquidGlassSurface(cornerRadius: 16, interactive: true)
        }
    }

    private var frequencyPreviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Frequency Preview")
                .font(.headline)
                .fontDesign(.rounded)

            VStack(alignment: .leading, spacing: 12) {
                frequencyRow(title: "Daily", days: habitStore.orderedWeekdays)
                frequencyRow(title: "Weekday", days: [1, 2, 3, 4, 5])
                frequencyRow(title: "Weekend", days: habitStore.weekStartsOnMonday ? [6, 0] : [0, 6])
                frequencyRow(title: "Custom", days: habitStore.orderedWeekdays)
            }
            .padding()
            .liquidGlassSurface(cornerRadius: 16, interactive: true)
        }
    }

    private func frequencyRow(title: String, days: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .fontDesign(.rounded)

            HStack(spacing: 8) {
                ForEach(days, id: \.self) { day in
                    Text(shortWeekdayName(for: day))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .frame(width: 38, height: 32)
                        .background(Color.primary.opacity(0.06))
                        .liquidGlassSurface(cornerRadius: 8)
                }
            }
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

#Preview {
    ProfileScreen()
        .modelContainer(previewContainer)
        .environment(HabitStore(modelContext: previewContainer.mainContext))
}

private let previewContainer: ModelContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try! ModelContainer(
        for: Habit.self, HabitEntry.self, HabitReminder.self, UserProfile.self,
        configurations: config
    )
}()
