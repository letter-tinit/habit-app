//
//  View+Extension.swift
//  Habit
//
//  Created by TiniT on 29/4/26.
//

import SwiftUI

extension View {
    func baseAnimation(_ changes: @escaping () -> Void) {
        withAnimation(.spring(duration: 0.3)) {
            changes()
        }
    }
    
    func clearDefaultConfigure() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

struct AppList<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        List {
            content
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}
