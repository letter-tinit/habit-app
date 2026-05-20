//
//  HomeScreen.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import SwiftUI

struct HomeScreen: View {
    @State private var progress = 0.6
    @Environment(HomeRouter.self) private var router
    @Environment(HabitStore.self) private var habitStore
    
    var body: some View {
        @Bindable var habitStore = habitStore
        BaseScreen {
            VStack(spacing: 0) {
                WeekView()
                    .padding(.horizontal)
                
                AppList {
                    ForEach(habitStore.filteredHabit, id: \.id) { habit in
                        HabitItemView(habit: habit, selectedDate: habitStore.selectedDate) { action in
                            handleHabitItemAction(action, for: habit)
                        }
                        .padding(.horizontal)
                        .swipeActions {
                            Button {
                                resetHabit(habit)
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .tint(.skyBlue)
                            }
                        }
                    }
                }
                // MARK: - List Configure
                .listRowSpacing(20)
                .contentMargins(.top, 20)
                
                Spacer()
            }
        }
        // MARK: - BaseScreen Configure
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                } label: {
                    HStack {
                        Text("All")
                        
                        Image(systemName: "arrow.down")
                            .resizable()
                            .frame(width: 10, height: 10)
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.push(.createHabit)
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .title) {
                Button {
                    
                } label: {
                    Text(habitStore.homeTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                }
            }
        }
    }
    
    private func handleHabitItemAction(_ action: HabitItemView.Action, for habit: Habit) {
        switch action {
        case .tapped:
            showHabitDetail(habit)
        case .progressChanged(let value):
            let wasCompleted = habit.entry(for: habitStore.selectedDate)?.isCompleted ?? false
            habitStore.updateHabitEntry(habit, completedCount: value)
            let isCompleted = habit.entry(for: habitStore.selectedDate)?.isCompleted ?? false
            
            if !wasCompleted && isCompleted {
                Haptic.success()
                SoundPlayer.done()
            }
        }
    }
    
    private func resetHabit(_ habit: Habit) {
        Haptic.warning()
        habitStore.resetHabitEntry(habit)
    }
    
    private func showHabitDetail(_ habit: Habit) {
        router.push(.habitDetail(habit.id))
    }
}

#Preview {
    HomeScreen()
}
