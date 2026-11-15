
import SwiftUI
import SwiftData

struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let goal: LearningGoal

    @State private var goalTitle: String
    @State private var selectedDuration: LearningDuration
    @State private var showResetConfirmation = false

    init(goal: LearningGoal) {
        self.goal = goal
        _goalTitle = State(initialValue: goal.title)
        _selectedDuration = State(initialValue: goal.duration)
    }
    private func saveChanges() {
        let newTitle = goalTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !newTitle.isEmpty else { return }

        let descriptor = FetchDescriptor<LearningDay>()

        do {
            let allDays = try modelContext.fetch(descriptor)

            let goalDays = allDays.filter { day in
                day.goal?.persistentModelID == goal.persistentModelID
            }

            // TODO: Confirm with mentor whether previous
            // learning history should be deleted or preserved.

            goal.title = newTitle
            goal.duration = selectedDuration
            goal.startDate = Date()
            goal.isCompleted = false

            try modelContext.save()
            dismiss()

        } catch {
            print("Failed to save goal changes: \(error)")
        }
    }
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Text("Edit Goal")
                    .font(.largeTitle.bold())

                Text("Learning Goal")
                    .font(.headline)

                TextField("Enter your goal", text: $goalTitle)
                    .padding()
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text("Duration")
                    .font(.headline)

                HStack(spacing: 12) {
                    ForEach(
                        [LearningDuration.week, .month, .year],
                        id: \.self
                    ) { duration in
                        Button {
                            selectedDuration = duration
                        } label: {
                            Text(duration.rawValue.capitalized)
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    selectedDuration == duration
                                        ? Color.orange
                                        : Color.white.opacity(0.12)
                                )
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 12)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }


                Spacer()
                Button {
                    showResetConfirmation = true
                } label: {
                    Text("Save Changes")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(goalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .foregroundStyle(.white)
        }
        .alert("Reset Learning Streak?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}

            Button("Confirm Reset", role: .destructive) {
                saveChanges()
            }
        } message: {
            Text("Changing your learning goal will reset your current streak. Do you want to continue?")
        }
    }
}

