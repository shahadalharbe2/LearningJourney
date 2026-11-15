import SwiftUI

struct GoalNotMetView: View {
    @State private var showNewGoal = false
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
                    showNewGoal = true
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
        .fullScreenCover(isPresented: $showNewGoal) {
            OnboardingView()
        }
    }
}

#Preview {
    GoalNotMetView()
}
