//
//  OnboardingView.swift
//  LearningJourney
//
//  Created by shahad on 02/06/1448 AH.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    private let viewModel = LearningGoalViewModel()
    @Query private var savedGoals: [LearningGoal]
    @State private var goalTitle = ""
    @State private var selectedDuration: LearningDuration = .week
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Hello Learner!")
                    .font(.largeTitle)
                    .bold()
                
                TextField("Enter your learning goal", text: $goalTitle)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                Picker("Learning Duration", selection: $selectedDuration) {
                    Text("Week").tag(LearningDuration.week)
                    Text("Month").tag(LearningDuration.month)
                    Text("Year").tag(LearningDuration.year)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                Button("Start Learning") {
                    viewModel.saveGoal(
                        title: goalTitle,
                        duration: selectedDuration,
                        context: modelContext
                    )
                    
                    print("Learning goal saved!")
                    dismiss()
                }
                .disabled(goalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding()
                
                Text("Saved goals: \(savedGoals.count)")
                    .font(.caption)
                
            }
            .padding()
        }
    }
}
    
    #Preview {
        OnboardingView()
    }

