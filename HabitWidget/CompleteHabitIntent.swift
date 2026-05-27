//
//  CompleteHabitIntent.swift
//  HabitWidget
//
//  Created by Codex on 27/5/26.
//

import AppIntents
import WidgetKit

struct CompleteHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Habit"
    static var description = IntentDescription("Marks a habit complete from the widget.")

    @Parameter(title: "Habit ID")
    var habitID: String

    @Parameter(title: "Completed Count")
    var completedCount: Int

    init() {}

    init(habitID: UUID, completedCount: Int) {
        self.habitID = habitID.uuidString
        self.completedCount = completedCount
    }

    func perform() async throws -> some IntentResult {
        guard let habitUUID = UUID(uuidString: habitID) else {
            return .result()
        }

        var snapshot = HabitWidgetStore.loadSnapshot()
        if let index = snapshot.habits.firstIndex(where: { $0.id == habitUUID }) {
            snapshot.habits[index].completedCount = completedCount
            HabitWidgetStore.saveSnapshot(snapshot)
        }

        HabitWidgetStore.appendAction(
            HabitWidgetAction(
                habitID: habitUUID,
                completedCount: completedCount
            )
        )
        WidgetCenter.shared.reloadTimelines(ofKind: "HabitTrackingWidget")

        return .result()
    }
}
