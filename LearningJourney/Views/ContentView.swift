//
//  ContentView.swift
//  LearningJourney
//
//  Created by shahad on 30/05/1448 AH.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @Query(sort: \LearningGoal.startDate, order: .reverse)
    private var savedGoals: [LearningGoal]

    @Query private var savedDays: [LearningDay]

    private let viewModel = LearningGoalViewModel()


    var body: some View {
        TimelineView(.everyMinute) { _ in
            let now = Date.now
            if let activeGoal = savedGoals.first(where: { !$0.isCompleted }) {
                
                if viewModel.hasGoalEnded(activeGoal, currentDate: now) {
                    if viewModel.isGoalSuccessful(activeGoal, days: savedDays, currentDate: now) {
                        GoalCompletedView()
                    } else {
                        GoalNotMetView()
                    }
                } else {
                    ActivityView(now: now)
                }
                
            } else {
                OnboardingView()
            }}
    }
}

#Preview {
    ContentView()
}
#Preview("Goal Completed") {
    GoalCompletedView()
}

#Preview("Goal Not Met") {
    GoalNotMetView()
}
