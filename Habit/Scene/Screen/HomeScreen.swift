//
//  HomeScreen.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import SwiftUI

struct HomeScreen: View {
    @State private var progress = 0.6
    @Environment(HabitStore.self) private var habitStore
    
    var body: some View {
        @Bindable var habitStore = habitStore
        BaseScreen($habitStore.homeTitle) {
            VStack(spacing: 0) {
                WeekView()
                    .padding(.horizontal)

                AppList {
                    ForEach($habitStore.habits.enumerated(), id: \.element.id) { index, $habit in
                        if index == 0 {
                            Color.clear
                                .frame(height: 0)
                        }

                        HabitItemView(habit: $habit)
                            .padding(.horizontal)
                            .swipeActions {
                                Button {
                                } label: {
                                    Image(systemName: "arrow.counterclockwise")
                                        .tint(.skyBlue)
                                }
                            }
                    }
                }
                .offset(y: -50)
                .listRowSpacing(20)
                // MARK: - List Configure
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
                    
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

#Preview {
    HomeScreen()
}
