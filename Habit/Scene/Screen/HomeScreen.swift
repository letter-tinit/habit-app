//
//  HomeScreen.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import SwiftUI

struct HomeScreen: View {
    @Environment(HabitStore.self) private var habitStore
    @State var progress: CGFloat = 0.2
    @State var text: String = "🤭"
    var originalText: String = "🤭"
    @FocusState private var isFocused: Bool
    private var focusBinding: Binding<Bool> {
        Binding(
            get: { isFocused },
            set: { isFocused = $0 }
        )
    }
    
    var body: some View {
        @Bindable var habitStore = habitStore
        BaseScreen($habitStore.homeTitle, isFocused: focusBinding) {
            AppList {
                ForEach(habitStore.habits, id: \.self) { habit in
                    HabitItemView(habit: habit, progress: $progress)
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
                        .swipeActions {
                            Button(role: .destructive) {
                                print("Delete")
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                
                VStack {
                    Button {
                        print("C")
                        isFocused = true
                    } label: {
                        VStack(alignment: .center, spacing: 10) {
                            Spacer(minLength: 30)
                            
                            Image(systemName: "plus.diamond.fill")
                                .resizable()
                                .font(.headline)
                                .frame(width: 36, height: 36)
                            
                            Text(text)
                                .font(.headline)
                        }
                        .foregroundStyle(.green)
                    }
                    
                    TextField("", text: $text)
                        .frame(height: 0)
                        .opacity(0)
                        .focused($isFocused)
                        .keyboardType(.emoji ?? .default)
                        .onChange(of: text) { _, newValue in
                            if let last = newValue.last, last.isEmoji {
                                text = String(last)
                            } else {
                                text = originalText
                            }
                        }
                }
            }
            // MARK: - List Configure
            .lineSpacing(.zero)
            
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
            
            ToolbarSpacer()
            
            ToolbarItem(placement: .keyboard) {
                Button {
                    isFocused = false
                } label: {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

#Preview {
    HomeScreen()
}
