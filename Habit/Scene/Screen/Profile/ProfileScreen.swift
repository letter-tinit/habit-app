//
//  ProfileScreen.swift
//  Habit
//
//  Created by TiniT on 19/5/26.
//

import SwiftUI
import SwiftData
import UIKit

struct ProfileScreen: View {
    @Environment(ProfileRouter.self) private var router
    @Environment(HabitStore.self) private var habitStore
    @State private var title = "Profile"

    var body: some View {
        BaseScreen($title, backgroundType: .cyan) {
            AppScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    profileSection
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

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Profile")
                .font(.headline)
                .fontDesign(.rounded)

            Button {
                router.push(.editProfile)
            } label: {
                HStack(spacing: 14) {
                    avatarView

                    VStack(alignment: .leading, spacing: 10) {
                        Text(habitStore.userProfile?.displayName ?? "You")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)

                        Text("Edit profile")
                            .font(.subheadline)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding()
            .liquidGlassSurface(cornerRadius: 16, interactive: true)
        }
    }

    private var avatarView: some View {
        Group {
            if let avatarData = habitStore.userProfile?.avatarData,
               let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .padding(10)
            }
        }
        .frame(width: 76, height: 76)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        }
        .liquidGlassSurface(cornerRadius: 38, interactive: true)
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
                        .mask {
                            RoundedRectangle(cornerRadius: 8)
                        }
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
        .environment(ProfileRouter())
}

private let previewContainer: ModelContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try! ModelContainer(
        for: Habit.self, HabitEntry.self, HabitReminder.self, UserProfile.self,
        configurations: config
    )
}()
