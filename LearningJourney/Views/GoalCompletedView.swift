import SwiftUI
import SwiftData

struct GoalCompletedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LearningGoal.startDate, order: .reverse)
    private var savedGoals: [LearningGoal]
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(.orange)

                Text("Goal Completed!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Great job! You've completed your learning goal.")
                    .font(.body)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)

                Spacer()

                Button {
                    if let goal = savedGoals.first(where: { !$0.isCompleted }) {
                        goal.isCompleted = true
                        try? modelContext.save()
                    }
                } label: {
                    Text("Set New Goal")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.black)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                }
            }
            .padding(24)
        }
    }
}

#Preview("Goal Completed - Test") {
    let container = try! ModelContainer(
        for: LearningGoal.self, LearningDay.self,
        configurations: ModelConfiguration(
            isStoredInMemoryOnly: true
        )
    )

    let testGoal = LearningGoal(
        title: "Test Completed Goal",
        duration: .week,
        startDate: Calendar.current.date(
            byAdding: .day,
            value: -8,
            to: Date()
        )!
    )

    container.mainContext.insert(testGoal)

    for dayOffset in 0..<7 {
        let dayDate = Calendar.current.date(
            byAdding: .day,
            value: dayOffset,
            to: testGoal.startDate
        )!

        let learningDay = LearningDay(
            date: dayDate,
            type: .learned,
            goal: testGoal
        )

        container.mainContext.insert(learningDay)
    }

    return ContentView()
        .modelContainer(container)
}
