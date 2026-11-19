
import SwiftUI
import SwiftData

struct ActivityView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \LearningGoal.startDate, order: .reverse)
    private var savedGoals: [LearningGoal]

    @Query private var savedDays: [LearningDay]

    @State private var showCalendar = false
    @State private var showEditGoal = false
    @State private var weekOffset = 0

    private let viewModel = LearningGoalViewModel()

    private let orange = Color(
        red: 1,
        green: 146.0 / 255,
        blue: 48.0 / 255
    )

    private let cyan = Color(
        red: 48.0 / 255,
        green: 204.0 / 255,
        blue: 239.0 / 255
    )

    private let dimmed = Color(white: 0.35)

    private var goal: LearningGoal? {
        savedGoals.first { !$0.isCompleted }
    }

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // MARK: - Header

                        HStack {
                            Text("Activity")
                                .font(.system(size: 34, weight: .bold))

                            Spacer()

                            headerButton(
                                "calendar",
                                label: "Calendar"
                            ) {
                                showCalendar = true
                            }

                            headerButton(
                                "pencil.and.outline",
                                label: "Edit learning goal"
                            ) {
                                showEditGoal = true
                            }
                        }

                        if let goal {

                            let days = viewModel.activityDays(
                                for: goal,
                                days: savedDays
                            )

                            let today = viewModel.activityType(
                                on: timeline.date,
                                days: days
                            )

                            let goalEnded = viewModel.hasGoalEnded(goal)

                            dateHeader(
                                timeline.date,
                                showsNavigation:
                                    !goalEnded &&
                                    (today == nil || weekOffset != 0)
                            )

                            weekStrip(
                                days: days,
                                today: timeline.date
                            )
                            .padding(.top, 14)

                            let freezes = viewModel.usedFreezes(
                                days: days
                            )

                            // MARK: - Counter Cards

                            HStack(spacing: 12) {

                                card(
                                    "flame.fill",
                                    count: viewModel.calculateStreak(
                                        days: days
                                    ),
                                    title: "Learned",
                                    color: orange
                                )

                                card(
                                    "snowflake",
                                    count: freezes,
                                    title: "Freezed",
                                    color: cyan
                                )
                            }
                            .padding(.top, 14)

                            if goalEnded {

                                goalResult(
                                    goal,
                                    availableHeight: geometry.size.height
                                )

                            } else {

                                activityButtons(
                                    goal: goal,
                                    today: today,
                                    freezes: freezes,
                                    width: min(
                                        272,
                                        max(
                                            0,
                                            geometry.size.width - 32
                                        )
                                    )
                                )
                                .padding(.top, 46)
                            }

                        } else {

                            Text("No learning goal yet")
                                .foregroundStyle(.gray)
                                .padding(.top, 40)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .buttonStyle(.plain)
        .sheet(isPresented: $showCalendar) {
            CalendarView()
        }
        .sheet(isPresented: $showEditGoal) {
            if let goal {
                EditGoalView(goal: goal)
            }
        }
    }

    // MARK: - Date Header

    private func dateHeader(
        _ date: Date,
        showsNavigation: Bool
    ) -> some View {

        HStack {

            Text(
                date,
                format: .dateTime
                    .weekday(.wide)
                    .day()
                    .month(.wide)
            )
            .font(.system(size: 17))
            .foregroundStyle(.gray)

            Spacer()

            if showsNavigation {

                Button {
                    weekOffset -= 1
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 24, height: 24)
                }
                .accessibilityLabel("Previous week")

                Button {
                    weekOffset += 1
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 24, height: 24)
                }
                .accessibilityLabel("Next week")
            }
        }
        .foregroundStyle(.blue)
        .frame(height: 24)
    }

    // MARK: - Header Buttons

    private func headerButton(
        _ symbol: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .glassEffect(.regular, in: Circle())
        }
        .accessibilityLabel(label)
    }

    // MARK: - Week Strip

    private func weekStrip(
        days: [LearningDay],
        today: Date
    ) -> some View {

        let calendar = Calendar.current

        let currentStart = calendar.dateInterval(
            of: .weekOfYear,
            for: today
        )?.start ?? today

        let start = calendar.date(
            byAdding: .day,
            value: 7 * weekOffset,
            to: currentStart
        ) ?? currentStart

        let dates = (0..<7).compactMap {
            calendar.date(
                byAdding: .day,
                value: $0,
                to: start
            )
        }

        return HStack(spacing: 0) {

            ForEach(dates, id: \.self) { date in

                let activity = viewModel.activityType(
                    on: date,
                    days: days
                )

                let isUnloggedToday =
                    activity == nil &&
                    calendar.isDate(
                        date,
                        inSameDayAs: today
                    )

                let tint = activity == .learned
                    ? orange
                    : cyan

                VStack(spacing: 4) {

                    Text(
                        date,
                        format: .dateTime.weekday(.narrow)
                    )
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )

                    Text(
                        date,
                        format: .dateTime.day()
                    )
                    .font(
                        .system(
                            size: 20,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        activity == nil
                            ? Color.white
                            : tint
                    )
                    .frame(width: 44, height: 44)
                    .background(
                        activity != nil
                            ? tint.opacity(0.13)
                            : isUnloggedToday
                                ? orange
                                : Color.clear,
                        in: Circle()
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Counter Card

    private func card(
        _ symbol: String,
        count: Int,
        title: String,
        color: Color
    ) -> some View {

        let shape = RoundedRectangle(
            cornerRadius: 30
        )

        return VStack(spacing: 4) {

            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundStyle(color)

            Text(
                "\(count) \(count == 1 ? "day" : "days")"
            )
            .font(
                .system(
                    size: 16,
                    weight: .semibold
                )
            )

            Text(title)
                .font(.system(size: 12))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 102)
        .background(
            Color(white: 0.10),
            in: shape
        )
        .overlay(
            shape.strokeBorder(
                .white.opacity(0.20)
            )
        )
    }

    // MARK: - Learn and Freeze Buttons

    private func activityButtons(
        goal: LearningGoal,
        today: LearningDayType?,
        freezes: Int,
        width: CGFloat
    ) -> some View {

        let limit = viewModel.freezeLimit(
            for: goal.duration
        )

        let learned = today == .learned
        let frozen = today == .frozen

        let learnDimmed = today != nil
        let freezeDimmed = today != nil || freezes >= limit

        return VStack(spacing: 0) {

            // Learn Button - Supports Undo

            Button {
                viewModel.logDay(
                    type: .learned,
                    goal: goal,
                    context: modelContext
                )
            } label: {

                Text(
                    learned
                        ? "Logged as Learned"
                        : "Log as Learned"
                )
                .font(
                    .system(
                        size: 16,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    learnDimmed ? dimmed : .white
                )
                .frame(
                    width: width,
                    height: width
                )
                .background(
                    (
                        learnDimmed
                            ? Color(white: 0.10)
                            : orange
                    ).gradient,
                    in: Circle()
                )
                .overlay(
                    Circle().strokeBorder(
                        .white.opacity(
                            learnDimmed ? 0.12 : 0.24
                        )
                    )
                )
            }
            .disabled(
                !viewModel.canLogDay(
                    type: .learned,
                    today: today,
                    freezesUsed: freezes,
                    duration: goal.duration
                )
            )
            .accessibilityHint(
                learned
                    ? "Double tap to undo today's learning activity"
                    : "Double tap to log today's learning activity"
            )

            // Freeze Button - Supports Undo

            Button {
                viewModel.logDay(
                    type: .frozen,
                    goal: goal,
                    context: modelContext
                )
            } label: {

                Text(
                    freezeDimmed
                        ? "Freezed for a day"
                        : "Freeze for a day"
                )
                .font(
                    .system(
                        size: 16,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    freezeDimmed ? dimmed : .white
                )
                .frame(
                    width: width,
                    height: 46
                )
                .background(
                    (
                        freezeDimmed
                            ? Color(white: 0.10)
                            : cyan
                    ).gradient,
                    in: Capsule()
                )
                .overlay(
                    Capsule().strokeBorder(
                        .white.opacity(0.20)
                    )
                )
            }
            .disabled(
                !viewModel.canLogDay(
                    type: .frozen,
                    today: today,
                    freezesUsed: freezes,
                    duration: goal.duration
                )
            )
            .accessibilityHint(
                frozen
                    ? "Double tap to undo today's freeze"
                    : "Double tap to freeze today's activity"
            )
            .padding(.top, 46)

            Text(
                "\(freezes) out of \(limit) Freezes used"
            )
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Goal Completed / Goal Not Met

    private func goalResult(
        _ goal: LearningGoal,
        availableHeight: CGFloat
    ) -> some View {

        let succeeded = viewModel.isGoalSuccessful(
            goal,
            days: savedDays
        )

        // Position result content proportionally
        // to the available device height.
        let resultTopSpacing = max(
            44,
            availableHeight * 0.075
        )

        let buttonTopSpacing = max(
            65,
            availableHeight * 0.12
        )

        return VStack(spacing: 0) {

            Image(
                systemName: succeeded
                    ? "hands.clap.fill"
                    : "xmark.seal.fill"
            )
            .font(.system(size: 42))
            .foregroundStyle(
                succeeded
                    ? Color.yellow
                    : orange
            )

            Text(
                succeeded
                    ? "Well done!"
                    : "You didn't reach your goal this time."
            )
            .font(
                .system(
                    size: 16,
                    weight: .semibold
                )
            )
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.top, 14)

            Text(
                succeeded
                    ? "Ready for your next goal?"
                    : "Want to set another goal?"
            )
            .font(.system(size: 13))
            .foregroundStyle(.gray)
            .multilineTextAlignment(.center)
            .padding(.top, 4)

            Button {

                goal.isCompleted = true

                do {
                    try modelContext.save()
                } catch {
                    print(
                        "Failed to complete goal: \(error)"
                    )
                }

            } label: {

                Label(
                    "Set a goal",
                    systemImage: "pencil.and.outline"
                )
                .font(
                    .system(
                        size: 15,
                        weight: .medium
                    )
                )
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(
                    orange,
                    in: Capsule()
                )
            }
            .padding(.top, buttonTopSpacing)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, resultTopSpacing)
    }
}

// MARK: - Preview: Activity

#Preview("Activity - Learned Days") {

    let container = try! ModelContainer(
        for: LearningGoal.self,
        LearningDay.self,
        configurations: ModelConfiguration(
            isStoredInMemoryOnly: true
        )
    )

    let calendar = Calendar.current

    let startDate = calendar.date(
        byAdding: .day,
        value: -4,
        to: .now
    )!

    let goal = LearningGoal(
        title: "Learn SwiftUI",
        duration: .week,
        startDate: startDate
    )

    container.mainContext.insert(goal)

    for offset in 0..<4 {

        let date = calendar.date(
            byAdding: .day,
            value: offset,
            to: startDate
        )!

        let day = LearningDay(
            date: date,
            type: offset >= 2
                ? .frozen
                : .learned,
            goal: goal
        )

        container.mainContext.insert(day)
    }

    return ActivityView()
        .modelContainer(container)
}

// MARK: - Preview: Goal Completed

#Preview("Goal Completed") {

    let container = try! ModelContainer(
        for: LearningGoal.self,
        LearningDay.self,
        configurations: ModelConfiguration(
            isStoredInMemoryOnly: true
        )
    )

    let calendar = Calendar.current

    let startDate = calendar.date(
        byAdding: .day,
        value: -8,
        to: .now
    )!

    let goal = LearningGoal(
        title: "Learn SwiftUI",
        duration: .week,
        startDate: startDate
    )

    container.mainContext.insert(goal)

    for offset in 0..<7 {

        let date = calendar.date(
            byAdding: .day,
            value: offset,
            to: startDate
        )!

        container.mainContext.insert(
            LearningDay(
                date: date,
                type: .learned,
                goal: goal
            )
        )
    }

    return ActivityView()
        .modelContainer(container)
}

// MARK: - Preview: Goal Not Met

#Preview("Goal Not Met") {

    let container = try! ModelContainer(
        for: LearningGoal.self,
        LearningDay.self,
        configurations: ModelConfiguration(
            isStoredInMemoryOnly: true
        )
    )

    let calendar = Calendar.current

    let startDate = calendar.date(
        byAdding: .day,
        value: -8,
        to: .now
    )!

    let goal = LearningGoal(
        title: "Learn SwiftUI",
        duration: .week,
        startDate: startDate
    )

    container.mainContext.insert(goal)

    for offset in 0..<2 {

        let date = calendar.date(
            byAdding: .day,
            value: offset,
            to: startDate
        )!

        container.mainContext.insert(
            LearningDay(
                date: date,
                type: .learned,
                goal: goal
            )
        )
    }

    return ActivityView()
        .modelContainer(container)
}
