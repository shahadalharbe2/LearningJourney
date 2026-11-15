import SwiftUI
import SwiftData

struct GoalNotMetView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \LearningGoal.startDate, order: .reverse)
    private var savedGoals: [LearningGoal]
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(.orange)

                Text("Goal Not Met")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Your learning goal has ended. Every step is progress. Keep learning!")
                    .font(.body)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)

                Spacer()

                Button {
                    if let goal = savedGoals.first(where: { !$0.isCompleted }) {
                        goal.isCompleted = true
                        try? modelContext.save()
                    }                } label: {
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

#Preview("Goal Not Met - Test") {
    let container = try! ModelContainer(
        for: LearningGoal.self, LearningDay.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let testGoal = LearningGoal(
        title: "Test Goal",
        duration: .week,
        startDate: Calendar.current.date(
            byAdding: .day,
            value: -8,
            to: Date()
        )!
    )

    container.mainContext.insert(testGoal)

    return ContentView()
        .modelContainer(container)
}
