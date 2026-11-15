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
    @State private var showCalendar = false
    @State private var showEditGoal = false
    // Temporary test date — remove after testing
    @State private var testDate = Calendar.current.date(
        byAdding: .day,
        value: 1,
        to: Date.now
    )!
    private let viewModel = LearningGoalViewModel()
    @Query(sort: \LearningGoal.startDate, order: .reverse)
    private var savedGoals: [LearningGoal]
    @Query private var savedDays: [LearningDay]
    private func isTodayLogged(for goal: LearningGoal) -> Bool {
        savedDays.contains { day in
            day.goal?.persistentModelID == goal.persistentModelID &&
            Calendar.current.isDateInToday(day.date)
        }
    }
    // TEMPORARY TEST — remove after testing
    private func addTestFreeze(for goal: LearningGoal) {
        let alreadyExists = daysForGoal(goal).contains { day in
            Calendar.current.isDate(day.date, inSameDayAs: testDate)
        }

        guard !alreadyExists else { return }

        let testDay = LearningDay(
            date: testDate,
            type: .frozen,
            goal: goal
        )

        modelContext.insert(testDay)
    }
    private func daysForGoal(_ goal: LearningGoal) -> [LearningDay] {
        savedDays.filter { day in
            day.goal?.persistentModelID == goal.persistentModelID
        }
    } // نهاية daysForGoal
    private func isLearnedDay(_ date: Date, goal: LearningGoal) -> Bool {
        daysForGoal(goal).contains { day in
            Calendar.current.isDate(day.date, inSameDayAs: date)
            && day.type == .learned
        }
    }
    private func isFrozenDay(_ date: Date, goal: LearningGoal) -> Bool {
        daysForGoal(goal).contains { day in
            Calendar.current.isDate(day.date, inSameDayAs: date)
            && day.type == .frozen
        }
    }
    // أضيفي الكود الجديد هنا
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = Date.now

        guard let week = calendar.dateInterval(
            of: .weekOfYear,
            for: today
        ) else {
            return []
        }

        return (0..<7).compactMap { day in
            calendar.date(
                byAdding: .day,
                value: day,
                to: week.start
            )
        }
    }
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16)  {
                HStack(alignment: .center) {

                    Text("Activity")
                        .font(.system(size: 30, weight: .bold))

                    Spacer()

                    Button {
                        showCalendar = true
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Circle())
                    }

                    Button {
                        showEditGoal = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Circle())
                    }
                }

                Text(
                    Date.now,
                    format: .dateTime
                        .weekday(.wide)
                        .day()
                        .month(.wide)
                )
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                // بداية كود أيام الأسبوع
                HStack(spacing: 4) {
                    ForEach(weekDates, id: \.self) { date in

                        let goal = savedGoals.first(where: { !$0.isCompleted })

                        let learned = goal.map {
                            isLearnedDay(date, goal: $0)
                        } ?? false

                        let frozen = goal.map {
                            isFrozenDay(date, goal: $0)
                        } ?? false

                        let isToday = Calendar.current.isDateInToday(date)

                        VStack(spacing: 6) {

                            Text(date, format: .dateTime.weekday(.narrow))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white)

                            Text(date, format: .dateTime.day())
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(
                                    isToday && !learned && !frozen
                                    ? .black : .white
                                )
                                .frame(width: 40, height: 40)
                                .background {
                                    Circle()
                                        .fill(
                                            learned ? Color.orange :
                                            frozen ? Color.cyan :
                                            isToday ? Color.white :
                                            Color.clear
                                        )
                                }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                // نهاية كود أيام الأسبوع

                                if let goal = savedGoals.first(where: { !$0.isCompleted })  {
                    let currentStreak = viewModel.calculateStreak(
                        days: daysForGoal(goal)
                    )
                    let freezesUsed = viewModel.usedFreezes(
                        days: daysForGoal(goal)
                    )
                    
                    let maxFreezes = viewModel.freezeLimit(
                        for: goal.duration
                    )
                    Text(goal.title)
                        .font(.title2)
                                    HStack(spacing: 12) {
                        VStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.orange)
                            
                            Text("\(currentStreak)")
                                .font(.title)
                                .bold()
                            
                            Text("Learned")
                                .font(.caption)
                        }
                        .padding(20)
                        .frame(width: 140)
                        .background(Color(white: 0.11))
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .overlay {
                            RoundedRectangle(cornerRadius: 26)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        }
                        
                        VStack(spacing: 8) {
                            Image(systemName: "snowflake")
                                .font(.system(size: 30))
                                .foregroundStyle(.cyan)
                            
                            Text("\(freezesUsed)")
                                .font(.title)
                                .bold()
                            
                            Text("Frozen")
                                .font(.caption)
                        }
                        .padding(20)
                        .frame(width: 140)
                        .background(Color(white: 0.11))
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .overlay {
                            RoundedRectangle(cornerRadius: 26)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        }
                    }
                    Button {
                        viewModel.logDay(
                            type: .learned,
                            goal: goal,
                            context: modelContext
                        )
                    } label: {
                        Text(isTodayLogged(for: goal) ? "Logged as Learned" : "Log as Learned")
                            .font(.headline)
                            .foregroundStyle(
                                isTodayLogged(for: goal)
                                ? Color.gray
                                : Color.white
                            )
                            .frame(width: 240, height: 240)
                            .background(
                                Circle()
                                    .fill(
                                        isTodayLogged(for: goal)
                                        ? Color(white: 0.11)
                                        : Color(red: 1.0, green: 0.55, blue: 0.15)
                                    )
                            )
                    }
                    .disabled(isTodayLogged(for: goal))
                    Button {
                        viewModel.logDay(
                            type: .frozen,
                            goal: goal,
                            context: modelContext
                        )
                    } label: {
                        Text(
                            isFrozenDay(Date.now, goal: goal)
                            ? "Freezed for a day"
                            : "Freeze for a day"
                        )
                        .font(.subheadline)
                        .foregroundStyle(
                            isTodayLogged(for: goal) || freezesUsed >= maxFreezes
                            ? Color.gray
                            : Color.white
                        )
                        .frame(width: 240, height: 44)
                        .background(
                            isTodayLogged(for: goal) || freezesUsed >= maxFreezes
                            ? Color(white: 0.11)
                            : Color.cyan
                        )
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        }
                    }
                    .disabled(
                        isTodayLogged(for: goal) ||
                        freezesUsed >= maxFreezes
                    )
                    Text("\(freezesUsed) out of \(maxFreezes) Freezes used")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if isTodayLogged(for: goal) {
                        Text("You've already logged today! ✓")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No learning goal yet")
                }
            } // نهاية VStack
            .frame(maxWidth: .infinity, maxHeight: .infinity,
                   alignment: .topLeading)
            .padding()
            .foregroundStyle(.white)

        } // نهاية ZStack
        .sheet(isPresented: $showCalendar) {
            CalendarView()
        }
        .sheet(isPresented: $showEditGoal) {
            if let goal = savedGoals.first(where: { !$0.isCompleted }) {
                EditGoalView(goal: goal)
            }
        }
    } // نهاية body
    } // نهاية ActivityView

    #Preview {
        ActivityView()
    }
