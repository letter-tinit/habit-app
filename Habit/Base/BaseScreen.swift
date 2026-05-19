//
//  BaseScreen.swift
//  Habit
//
//  Created by TiniT on 28/4/26.
//

import SwiftUI

struct BaseScreen<Content: View>: View {
    // MARK: - ENUM
    enum BackgroundGradientType {
        case mintCyan
        case lightPink
        case mint
        case cyan
        case custom(LinearGradient)
    }
    
    private var backgroundGradient: LinearGradient {
        switch backgroundType {
        case .mintCyan:
            return LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.95, green: 1.0, blue: 0.98), location: 0.0),  // soft mint white
                    .init(color: Color(red: 0.88, green: 1.0, blue: 0.96), location: 0.3),  // pastel mint
                    .init(color: Color(red: 0.84, green: 0.98, blue: 1.0), location: 0.65), // light cyan
                    .init(color: Color(red: 0.78, green: 0.95, blue: 1.0), location: 1.0)   // soft aqua cyan
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .mint:
            return LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.96, green: 1.0, blue: 0.98), location: 0.0),
                    .init(color: Color(red: 0.88, green: 1.0, blue: 0.94), location: 0.4),
                    .init(color: Color(red: 0.76, green: 0.96, blue: 0.88), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cyan:
            return LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.95, green: 0.99, blue: 1.0), location: 0.0),
                    .init(color: Color(red: 0.85, green: 0.97, blue: 1.0), location: 0.4),
                    .init(color: Color(red: 0.72, green: 0.93, blue: 1.0), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .lightPink:
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.985, blue: 0.99), // ultra light pink
                    Color(red: 1.0, green: 0.975, blue: 0.985), // soft airy blush
                    Color(red: 1.0, green: 0.965, blue: 0.98), // subtle pastel pink
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .custom(let linearGradient):
            return linearGradient
        }
    }
    
    
    
    // MARK: - Property
    @Binding private var title: String
    private var backgroundType: BackgroundGradientType
    private var content: () -> Content
    @Binding private var isFocused: Bool
    
    init(
        _ title: Binding<String>,
        backgroundType: BackgroundGradientType = .lightPink,
        isFocused: Binding<Bool> = .constant(false),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._title = title
        self.backgroundType = backgroundType
        self.content = content
        self._isFocused = isFocused
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            content()
            
            Color.gray.opacity(isFocused ? 0.0001 : 0)
                .onTapGesture {
                    if isFocused {
                        isFocused = false
                    }
                }
                .ignoresSafeArea()
        }
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .title) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
            }
        }
    }
}
