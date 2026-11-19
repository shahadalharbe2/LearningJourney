
//
//  EditGoalView.swift
//  LearningJourney
//

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
        let newTitle = goalTitle.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !newTitle.isEmpty else { return }

        do {
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

                // MARK: - Header

                HStack {

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .glassEffect(.regular, in: Circle())
                    }
                    .accessibilityLabel("Back")

                    Spacer()

                    Text("Learning Goal")
                        .font(.headline)

                    Spacer()

                    Button {
                        showResetConfirmation = true
                    } label: {
                        Image(systemName: "checkmark")
                            .font(
                                .system(
                                    size: 20,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                    .disabled(
                        goalTitle.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                    .accessibilityLabel("Update learning goal")
                }

                // MARK: - Learning Goal

                VStack(alignment: .leading, spacing: 12) {

                    Text("I want to learn")
                        .font(.system(size: 16))

                    TextField("Swift", text: $goalTitle)
                        .font(.system(size: 16))
                        .padding(.vertical, 12)

                    Divider()
                        .background(Color.gray.opacity(0.4))
                }
                .padding(.top, 24)

                // MARK: - Duration Selection

                VStack(alignment: .leading, spacing: 16) {

                    Text("I want to learn it in a")
                        .font(.system(size: 16))

                    HStack(spacing: 12) {

                        ForEach(
                            [
                                LearningDuration.week,
                                .month,
                                .year
                            ],
                            id: \.self
                        ) { duration in

                            Button {
                                selectedDuration = duration
                            } label: {
                                Text(duration.rawValue.capitalized)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 22)
                                    .padding(.vertical, 12)
                                    .glassEffect(
                                        .regular.tint(
                                            selectedDuration == duration
                                                ? .orange
                                                : .clear
                                        ),
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
            .foregroundStyle(.white)

            // MARK: - Update Confirmation

            if showResetConfirmation {

                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showResetConfirmation = false
                    }

                VStack(alignment: .leading, spacing: 20) {

                    Text("Update goal")
                        .font(
                            .system(
                                size: 16,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.white)

                    Text(
                        "If you update now, your streak will start over."
                    )
                    .font(.system(size: 16))
                    .foregroundStyle(.gray)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                    HStack(spacing: 8) {

                        Button("Dismiss") {
                            showResetConfirmation = false
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            Color(
                                red: 0.20,
                                green: 0.20,
                                blue: 0.22
                            )
                        )
                        .clipShape(Capsule())

                        Button("Update") {
                            showResetConfirmation = false
                            saveChanges()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.orange)
                        .clipShape(Capsule())
                    }
                    .font(
                        .system(
                            size: 16,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.white)
                }
                .padding(14)
                .frame(width: 300)
                .background(
                    Color(
                        red: 0.10,
                        green: 0.10,
                        blue: 0.10
                    )
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 32)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            Color.white.opacity(0.18),
                            lineWidth: 1
                        )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Edit Goal - Test") {

    let container = try! ModelContainer(
        for: LearningGoal.self,
        LearningDay.self,
        configurations: ModelConfiguration(
            isStoredInMemoryOnly: true
        )
    )

    let goal = LearningGoal(
        title: "Learn SwiftUI",
        duration: .month,
        startDate: .now
    )

    container.mainContext.insert(goal)

    return EditGoalView(goal: goal)
        .modelContainer(container)
}
