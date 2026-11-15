import SwiftUI

struct GoalCompletedView: View {
    @State private var showNewGoal = false
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
                    showNewGoal = true                } label: {
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
        .fullScreenCover(isPresented: $showNewGoal) {
            OnboardingView()
        }
    }
}

#Preview {
    GoalCompletedView()
}
