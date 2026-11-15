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
        Group {
            if let activeGoal = savedGoals.first(where: { !$0.isCompleted }) {
                
                if viewModel.hasGoalEnded(activeGoal) {
                    if viewModel.isGoalSuccessful(activeGoal, days: savedDays) {
                        GoalCompletedView()
                    } else {
                        GoalNotMetView()
                    }
                } else {
                    ActivityView()
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
