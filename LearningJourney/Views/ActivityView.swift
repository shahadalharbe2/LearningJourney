//
//  ActivityView.swift
//  LearningJourney
//
//  Created by shahad on 02/06/1448 AH.
//

import SwiftUI
import SwiftData

struct ActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LearningGoal.startDate, order: .reverse) private var savedGoals: [LearningGoal]
    @Query private var savedDays: [LearningDay]
    @State private var showCalendar = false
    @State private var showEditGoal = false
    @State private var weekOffset = 0
    private let viewModel = LearningGoalViewModel()
    private let orange = Color(red: 1, green: 146.0 / 255, blue: 48.0 / 255)
    private let cyan = Color(red: 48.0 / 255, green: 204.0 / 255, blue: 239.0 / 255)
    private let dimmed = Color(white: 0.35)

    private var goal: LearningGoal? { savedGoals.first { !$0.isCompleted } }

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Activity").font(.system(size: 34, weight: .bold))
                            Spacer()
                            headerButton("calendar", label: "Calendar") { showCalendar = true }
                            headerButton("pencil.and.outline", label: "Edit learning goal") { showEditGoal = true }
                        }

                        if let goal {
                            let days = viewModel.activityDays(for: goal, days: savedDays)
                            let today = viewModel.activityType(on: timeline.date, days: days)
                            dateHeader(timeline.date, showsNavigation: today == nil || weekOffset != 0)
                            weekStrip(days: days, today: timeline.date)
                                .padding(.top, 14)

                            if viewModel.hasGoalEnded(goal) {
                                goalResult(goal)
                            } else {
                                let freezes = viewModel.usedFreezes(days: days)
                                HStack(spacing: 12) {
                                    card("flame.fill", count: viewModel.calculateStreak(days: days),
                                         title: "Learned", color: orange)
                                    card("snowflake", count: freezes, title: "Freezed", color: cyan)
                                }
                                .padding(.top, 14)

                                activityButtons(
                                    goal: goal, today: today, freezes: freezes,
                                    width: min(272, max(0, geometry.size.width - 32))
                                )
                                .padding(.top, 46)
                            }
                        } else {
                            Text("No learning goal yet")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .buttonStyle(.plain)
        .sheet(isPresented: $showCalendar) { CalendarView() }
        .sheet(isPresented: $showEditGoal) {
            if let goal { EditGoalView(goal: goal) }
        }
    }

    private func dateHeader(_ date: Date, showsNavigation: Bool) -> some View {
        HStack {
            Text(date, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.system(size: 17))
                .foregroundStyle(.gray)
            Spacer()
            if showsNavigation {
                Button { weekOffset -= 1 } label: {
                    Image(systemName: "chevron.left").frame(width: 24, height: 24)
                }
                .accessibilityLabel("Previous week")
                Button { weekOffset += 1 } label: {
                    Image(systemName: "chevron.right").frame(width: 24, height: 24)
                }
                .accessibilityLabel("Next week")
            }
        }
        .foregroundStyle(.blue)
        .frame(height: 24)
    }

    private func headerButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .glassEffect(.regular, in: Circle())
        }
        .accessibilityLabel(label)
    }

    private func weekStrip(days: [LearningDay], today: Date) -> some View {
        let calendar = Calendar.current
        let currentStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let start = calendar.date(byAdding: .day, value: 7 * weekOffset, to: currentStart) ?? currentStart
        let dates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }

        return HStack(spacing: 0) {
            ForEach(dates, id: \.self) { date in
                let activity = viewModel.activityType(on: date, days: days)
                let isUnloggedToday = activity == nil && calendar.isDate(date, inSameDayAs: today)
                let tint = activity == .learned ? orange : cyan

                VStack(spacing: 4) {
                    Text(date, format: .dateTime.weekday(.narrow))
                        .font(.system(size: 13, weight: .semibold))
                    Text(date, format: .dateTime.day())
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(activity == nil ? Color.white : tint)
                        .frame(width: 44, height: 44)
                        .background(
                            activity != nil ? tint.opacity(0.13) : isUnloggedToday ? orange : Color.clear,
                            in: Circle()
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func card(_ symbol: String, count: Int, title: String, color: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: 30)
        return VStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 22)).foregroundStyle(color)
            Text("\(count) \(count == 1 ? "day" : "days")").font(.system(size: 16, weight: .semibold))
            Text(title).font(.system(size: 12))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 102)
        .background(Color(white: 0.10), in: shape)
        .overlay(shape.strokeBorder(.white.opacity(0.20)))
    }

    private func activityButtons(goal: LearningGoal, today: LearningDayType?, freezes: Int, width: CGFloat) -> some View {
        let limit = viewModel.freezeLimit(for: goal.duration)
        let learned = today == .learned
        let frozenOrExhausted = today == .frozen || freezes >= limit

        return VStack(spacing: 0) {
            Button {
                viewModel.logDay(type: .learned, goal: goal, context: modelContext)
            } label: {
                Text(learned ? "Logged as Learned" : "Log as Learned")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(learned ? dimmed : .white)
                    .frame(width: width, height: width)
                    .background((learned ? Color(white: 0.10) : orange).gradient, in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(learned ? 0.12 : 0.24)))
            }
            .disabled(!viewModel.canLogDay(type: .learned, today: today, freezesUsed: freezes, duration: goal.duration))

            Button {
                viewModel.logDay(type: .frozen, goal: goal, context: modelContext)
            } label: {
                Text(frozenOrExhausted ? "Freezed for a day" : "Freeze for a day")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(frozenOrExhausted ? dimmed : .white)
                    .frame(width: width, height: 46)
                    .background((frozenOrExhausted ? Color(white: 0.10) : cyan).gradient, in: Capsule())
                    .overlay(Capsule().strokeBorder(.white.opacity(0.20)))
            }
            .disabled(!viewModel.canLogDay(type: .frozen, today: today, freezesUsed: freezes, duration: goal.duration))
            .padding(.top, 46)

            Text("\(freezes) out of \(limit) Freezes used")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity)
    }

    private func goalResult(_ goal: LearningGoal) -> some View {
        let succeeded = viewModel.isGoalSuccessful(goal, days: savedDays)
        return VStack(spacing: 20) {
            Image(systemName: succeeded ? "hands.clap.fill" : "xmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(succeeded ? Color.yellow : Color.orange)
            Text(succeeded ? "Well done!" : "You didn't reach your goal this time.").font(.headline)
            Text(succeeded ? "Ready for your next goal?" : "Want to set another goal?")
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

#Preview("Activity - Learned Days") {
    let container = try! ModelContainer(
        for: LearningGoal.self, LearningDay.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
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
            type: offset >= 2 ? .frozen : .learned,
            goal: goal
        )

        container.mainContext.insert(day)
    }

    return ActivityView()
        .modelContainer(container)
}
