import SwiftUI
import SwiftData

struct CalendarView: View {

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \LearningGoal.startDate, order: .reverse)
    private var savedGoals: [LearningGoal]

    @Query private var savedDays: [LearningDay]

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        return calendar
    }
    private func dayType(for date: Date) -> LearningDayType? {
        return savedDays
            .filter { day in
                calendar.isDate(day.date, inSameDayAs: date)
            }
            .sorted { $0.date > $1.date }
            .first?
            .type
    }
    private func dayColor(for date: Date) -> Color {
        switch dayType(for: date) {
        case .learned:
            return .orange
        case .frozen:
            return .cyan
        case nil:
            return .clear
        }
    }

    private var months: [Date] {
        let year = calendar.component(.year, from: Date.now)

        let firstActivityYear = savedDays.map { calendar.component(.year, from: $0.date) }.min() ?? year

        return (min(firstActivityYear, year)...year).flatMap { activityYear in
            (1...12).compactMap { month in
                calendar.date(from: DateComponents(year: activityYear, month: month, day: 1))
            }
        }
    }
    private func daysInMonth(_ month: Date) -> [Date?] {
        guard let interval = calendar.dateInterval(
            of: .month,
            for: month
        ),
        let numberOfDays = calendar.range(
            of: .day,
            in: .month,
            for: month
        ) else {
            return []
        }

        let firstWeekday = calendar.component(
            .weekday,
            from: interval.start
        )

        // Calendar.current uses Sunday = 1 in the Gregorian calendar.
        let emptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7

        let placeholders = Array<Date?>(
            repeating: nil,
            count: emptyDays
        )

        let dates: [Date?] = numberOfDays.compactMap { day in
            calendar.date(
                byAdding: .day,
                value: day - 1,
                to: interval.start
            )
        }

        return placeholders + dates
    }
    private func monthView(_ month: Date) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            Text(month, format: .dateTime.month(.wide).year())
                .font(.system(size: 18, weight: .semibold))

            HStack(spacing: 0) {
                ForEach(["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 4),
                    count: 7
                ),
                spacing: 12
            ) {
                ForEach(Array(daysInMonth(month).enumerated()), id: \.offset) { _, date in
                    if let date {
                        let type = dayType(for: date)

                        Text(date, format: .dateTime.day())
                            .font(.system(size: 16))                            .foregroundStyle(
                                type == nil ? Color.white :
                                dayColor(for: date)
                            )
                            .frame(width: 40, height: 40)
                            .background {
                                Circle()
                                    .fill(
                                        type == nil
                                        ? Color.clear
                                        : dayColor(for: date).opacity(0.12)
                                    )
                            }
                            .frame(maxWidth: .infinity)
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("Activities")
                        .font(.headline)

                    Spacer()

                    // مساحة موازنة لتوسيط العنوان
                    Color.clear
                        .frame(width: 44, height: 44)
                }

                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(months, id: \.self) { month in
                            monthView(month)

                            Divider()
                                .background(Color.gray.opacity(0.3))
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .padding()
            .foregroundStyle(.white)
        }
    }
}

#Preview("Calendar - Test") {
    let container = try! ModelContainer(
        for: LearningGoal.self, LearningDay.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let calendar = Calendar.current

    let goal = LearningGoal(
        title: "Learn SwiftUI",
        duration: .month,
        startDate: .now
    )

    container.mainContext.insert(goal)

    for offset in 0..<5 {
        let date = calendar.date(
            byAdding: .day,
            value: -offset,
            to: .now
        )!

        let day = LearningDay(
            date: date,
            type: offset < 3 ? .learned : .frozen,
            goal: goal
        )

        container.mainContext.insert(day)
    }

    return CalendarView()
        .modelContainer(container)
}
