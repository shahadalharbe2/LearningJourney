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
    @State private var goalTitle = ""
    @State private var selectedDuration: LearningDuration = .week
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)

                Text("Hello Learner")
                    .font(.largeTitle)
                    .bold()
                Text("This app will help you learn everyday!")
                    .foregroundStyle(.secondary)
                
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
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .buttonBorderShape(.capsule)
                .disabled(goalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding()
                
                Text("You can edit your desire later")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
        }
        .preferredColorScheme(.dark)
    }
}
    
    #Preview {
        OnboardingView()
    }

