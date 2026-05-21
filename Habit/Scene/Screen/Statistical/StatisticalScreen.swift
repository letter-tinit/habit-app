//
//  StatisticalScreen.swift
//  Habit
//
//  Created by TiniT on 21/5/26.
//

import SwiftUI

struct StatisticalScreen: View {
    @State private var statisticsScope: StatisticsScope = .month
    @State private var title: String = "Statistical"

    var body: some View {
        BaseScreen($title, backgroundType: .mint) {
            VStack {
                StatisticsOverviewView(scope: $statisticsScope)
                    .padding(.horizontal)
                    .padding(.top, 14)
                
                Spacer()
            }
        }
    }
}

#Preview {
    StatisticalScreen()
}
