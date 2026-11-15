//
//  LearningGoalViewModel.swift
//  LearningJourney
//
//  Created by shahad on 02/06/1448 AH.
//

import Foundation
import SwiftData
@MainActor
final class LearningGoalViewModel {
    func saveGoal(
        title: String,
        duration: LearningDuration,
        context: ModelContext
    ) {
        let newGoal = LearningGoal(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            duration: duration,
            startDate: Date()
        )
        
        context.insert(newGoal)
    }
    func logDay(
        type: LearningDayType,
        goal: LearningGoal,
        context: ModelContext
    ) {
        let calendar = Calendar.current
        guard !hasGoalEnded(goal) else {
            print("Goal has already ended!")
            return
        }
        let descriptor = FetchDescriptor<LearningDay>()
        
        guard let savedDays = try? context.fetch(descriptor) else {
            return
        }
        
        let alreadyLogged = savedDays.contains { day in
            day.goal?.persistentModelID == goal.persistentModelID &&
            day.date >= goal.startDate &&
            calendar.isDate(day.date, inSameDayAs: Date())
        }
        guard !alreadyLogged else {
            print("This day is already logged!")
            return
        }
        if type == .frozen {
            let goalDays = savedDays.filter { day in
                day.goal?.persistentModelID == goal.persistentModelID &&
                day.date >= goal.startDate
            }

            guard let lastDay = goalDays.max(by: { $0.date < $1.date }) else {
                print("Freeze requires a previous learning day!")
                return
            }

            let hoursSinceLastLog = Date.now.timeIntervalSince(lastDay.date) / 3600

            guard hoursSinceLastLog <= 32 else {
                print("Streak expired! Freeze cannot restore it.")
                return
            }
            
            let freezesUsed = usedFreezes(days: goalDays)
            let maxFreezes = freezeLimit(for: goal.duration)
            
            guard freezesUsed < maxFreezes else {
                print("Freeze limit reached!")
                return
            }
        }
        let newDay = LearningDay(
            date: Date(),
            type: type,
            goal: goal
        )
        
        context.insert(newDay)
    }
    func calculateStreak(
        days: [LearningDay],
        currentDate: Date = Date()
    ) -> Int {
        let sortedDays = days.sorted { $0.date > $1.date }
        guard let latestDay = sortedDays.first else {
            return 0
        }
        let hoursSinceLastLog = currentDate.timeIntervalSince(latestDay.date) / 3600
        if hoursSinceLastLog > 32 {
            return 0
        }
        var streak = 0
        var previousDate: Date?
        for day in sortedDays {
            if let previousDate = previousDate {
                let hoursBetweenLogs =
                previousDate.timeIntervalSince(day.date) / 3600
                
                if hoursBetweenLogs > 32 {
                    break
                }
            }
            if day.type == .learned {
                streak += 1
            }
            previousDate = day.date
        }
        
        return streak    }
    func freezeLimit(for duration: LearningDuration) -> Int {
        switch duration {
        case .week:
            return 2
        case .month:
            return 8
        case .year:
            return 96
        }
    }
    
    func usedFreezes(days: [LearningDay]) -> Int {
        days.filter { day in
            day.type == .frozen
        }.count
    }
    func goalEndDate(for goal: LearningGoal) -> Date? {
        let calendar = Calendar.current
        
        switch goal.duration {
        case .week:
            return calendar.date(
                byAdding: .day,
                value: 7,
                to: goal.startDate
            )
            
        case .month:
            return calendar.date(
                byAdding: .month,
                value: 1,
                to: goal.startDate
            )
            
        case .year:
            return calendar.date(
                byAdding: .year,
                value: 1,
                to: goal.startDate
            )
        }
    }
    func hasGoalEnded(_ goal: LearningGoal) -> Bool {
        guard let endDate = goalEndDate(for: goal) else {
            return false
        }
        
        return Date.now >= endDate
    }
    func learnedDaysCount(
        for goal: LearningGoal,
        days: [LearningDay]
    ) -> Int {
        days.filter { day in
            day.goal?.persistentModelID == goal.persistentModelID &&
            day.type == .learned &&
            day.date >= goal.startDate &&
            (goalEndDate(for: goal).map { day.date < $0 } ?? false)
        }.count
    }
    
    func isGoalSuccessful(
        _ goal: LearningGoal,
        days: [LearningDay],
        currentDate: Date = .now
    ) -> Bool {
        guard let endDate = goalEndDate(for: goal),
              currentDate >= endDate else {
            return false
        }
        
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: goal.startDate)
        
        let totalDays = calendar.dateComponents(
            [.day],
            from: start,
            to: calendar.startOfDay(for: endDate)
        ).day ?? 0
        
        guard totalDays > 0 else { return false }
        let goalDays = days.filter { day in
            day.goal?.persistentModelID == goal.persistentModelID &&
            day.date >= goal.startDate &&
            day.date < endDate
        }
        
        let freezeCount = goalDays.filter {
            $0.type == .frozen
        }.count
        
        guard freezeCount <= freezeLimit(for: goal.duration) else {
            return false
        }
        
        
        let learnedDates = Set(
            goalDays
                .filter { $0.type == .learned }
                .map { calendar.startOfDay(for: $0.date) }
        )
        
        let requiredLearnedDays = totalDays - freezeLimit(for: goal.duration)
        
        let frozenDates = Set(
            goalDays
                .filter { $0.type == .frozen }
                .map { calendar.startOfDay(for: $0.date) }
        )
        
        let completedDates = learnedDates.union(frozenDates)
        
        return learnedDates.count >= requiredLearnedDays &&
        completedDates.count == totalDays
        
        
    }}
#if DEBUG
func testStreak() {
    let viewModel = LearningGoalViewModel()
    let calendar = Calendar.current
    let now = Date.now

    let goal = LearningGoal(
        title: "Streak Test",
        duration: .week,
        startDate: calendar.date(
            byAdding: .day,
            value: -5,
            to: now
        )!
    )

    let days = [
        LearningDay(
            date: now.addingTimeInterval(-60 * 60 * 60),
            type: .learned,
            goal: goal
        ),
        LearningDay(
            date: now.addingTimeInterval(-24 * 60 * 60),
            type: .frozen,
            goal: goal
        ),
        LearningDay(
            date: now,
            type: .learned,
            goal: goal
        )
    ]
    let testTime = now
    let streak = viewModel.calculateStreak(
        days: days,
        currentDate: testTime
    )

    print("🔥 Streak Test Result: \(streak)")
}
#endif


