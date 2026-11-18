//
//  LearningJourneyTests.swift
//  LearningJourneyTests
//
//  Created by shahad on 05/06/1448 AH.
//
import Foundation
import Testing
import SwiftData
@testable import LearningJourney

struct LearningJourneyTests {
    @MainActor

    @Test func freezeLimitsAreCorrect() {
        let viewModel = LearningGoalViewModel()

        #expect(viewModel.freezeLimit(for: .week) == 2)
        #expect(viewModel.freezeLimit(for: .month) == 8)
        #expect(viewModel.freezeLimit(for: .year) == 96)
    }
    @Test
    @MainActor
    func learnedDaysCountStartsAtZero() {
        let viewModel = LearningGoalViewModel()

        let goal = LearningGoal(
            title: "Learn SwiftUI",
            duration: .week,
            startDate: .now
        )

        let count = viewModel.learnedDaysCount(
            for: goal,
            days: []
        )

        #expect(count == 0)
    }
    @Test
    @MainActor
    func freezeDoesNotCountAsLearned() {
        let viewModel = LearningGoalViewModel()

        let startDate = Date.now

        let goal = LearningGoal(
            title: "Learn SwiftUI",
            duration: .week,
            startDate: startDate
        )

        let learnedDay = LearningDay(
            date: startDate,
            type: .learned,
            goal: goal
        )

        let frozenDay = LearningDay(
            date: Calendar.current.date(
                byAdding: .day,
                value: 1,
                to: startDate
            )!,
            type: .frozen,
            goal: goal
        )

        let days = [learnedDay, frozenDay]

        #expect(viewModel.learnedDaysCount(for: goal, days: days) == 1)
        #expect(viewModel.usedFreezes(days: days) == 1)
    }
    @Test
    @MainActor
    func weeklyGoalSucceedsWithFiveLearnAndTwoFreeze() {
        let viewModel = LearningGoalViewModel()
        let calendar = Calendar.current

        let startDate = calendar.startOfDay(
            for: calendar.date(
                byAdding: .day,
                value: -8,
                to: .now
            )!
        )

        let goal = LearningGoal(
            title: "Learn SwiftUI",
            duration: .week,
            startDate: startDate
        )

        let days = (0..<7).map { offset in
            LearningDay(
                date: calendar.date(
                    byAdding: .day,
                    value: offset,
                    to: startDate
                )!,
                type: offset < 5 ? .learned : .frozen,
                goal: goal
            )
        }

        #expect(
            viewModel.isGoalSuccessful(
                goal,
                days: days
            ) == true
        )
    }
    @Test
    @MainActor
    func weeklyGoalFailsWhenOneDayIsMissing() {
        let viewModel = LearningGoalViewModel()
        let calendar = Calendar.current

        let startDate = calendar.startOfDay(
            for: calendar.date(
                byAdding: .day,
                value: -8,
                to: .now
            )!
        )

        let goal = LearningGoal(
            title: "Learn SwiftUI",
            duration: .week,
            startDate: startDate
        )

        let days = (0..<6).map { offset in
            LearningDay(
                date: calendar.date(
                    byAdding: .day,
                    value: offset,
                    to: startDate
                )!,
                type: offset < 5 ? .learned : .frozen,
                goal: goal
            )
        }

        #expect(
            viewModel.isGoalSuccessful(
                goal,
                days: days
            ) == false
        )
    }
    @Test
    @MainActor
    func weeklyGoalFailsWhenFreezeLimitExceeded() {
        let viewModel = LearningGoalViewModel()
        let calendar = Calendar.current

        let startDate = calendar.startOfDay(
            for: calendar.date(
                byAdding: .day,
                value: -8,
                to: .now
            )!
        )

        let goal = LearningGoal(
            title: "Learn SwiftUI",
            duration: .week,
            startDate: startDate
        )

        let days = (0..<7).map { offset in
            LearningDay(
                date: calendar.date(
                    byAdding: .day,
                    value: offset,
                    to: startDate
                )!,
                type: offset < 4 ? .learned : .frozen,
                goal: goal
            )
        }

        #expect(
            viewModel.isGoalSuccessful(
                goal,
                days: days
            ) == false
        )
    }
    @Test
    @MainActor
    func streakResetsAfter32Hours() {
        let viewModel = LearningGoalViewModel()

        let logDate = Date.now

        let goal = LearningGoal(
            title: "Learn SwiftUI",
            duration: .week,
            startDate: logDate
        )

        let learnedDay = LearningDay(
            date: logDate,
            type: .learned,
            goal: goal
        )

        let after31Hours = logDate.addingTimeInterval(31 * 3600)
        let after32Hours = logDate.addingTimeInterval(32 * 3600)
        let after33Hours = logDate.addingTimeInterval(33 * 3600)

        #expect(
            viewModel.calculateStreak(
                days: [learnedDay],
                currentDate: after31Hours
            ) == 1
        )

        #expect(
            viewModel.calculateStreak(
                days: [learnedDay],
                currentDate: after32Hours
            ) == 1
        )

        #expect(
            viewModel.calculateStreak(
                days: [learnedDay],
                currentDate: after33Hours
            ) == 0
        )
    }
    @Test
    @MainActor
    func freezePreservesStreak() {
        let viewModel = LearningGoalViewModel()
        let calendar = Calendar.current

        let startDate = Date.now

        let goal = LearningGoal(
            title: "Learn SwiftUI",
            duration: .week,
            startDate: startDate
        )

        let firstLearn = LearningDay(
            date: startDate,
            type: .learned,
            goal: goal
        )

        let freezeDay = LearningDay(
            date: calendar.date(
                byAdding: .hour,
                value: 24,
                to: startDate
            )!,
            type: .frozen,
            goal: goal
        )

        let secondLearn = LearningDay(
            date: calendar.date(
                byAdding: .hour,
                value: 48,
                to: startDate
            )!,
            type: .learned,
            goal: goal
        )

        let days = [firstLearn, freezeDay, secondLearn]

        let streak = viewModel.calculateStreak(
            days: days,
            currentDate: secondLearn.date
        )

        #expect(streak == 2)
        #expect(viewModel.usedFreezes(days: days) == 1)
        #expect(viewModel.learnedDaysCount(for: goal, days: days) == 2)
    }
    @Test
    @MainActor
    func cannotLogTwiceOnSameDay() throws {
        let container = try ModelContainer(
            for: LearningGoal.self, LearningDay.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let context = container.mainContext
        let viewModel = LearningGoalViewModel()

        let goal = LearningGoal(
            title: "Learn SwiftUI",
            duration: .week,
            startDate: .now
        )

        context.insert(goal)

        // First: Log a learning day
        viewModel.logDay(
            type: .learned,
            goal: goal,
            context: context
        )

        // Second: Try to freeze the same day
        viewModel.logDay(
            type: .frozen,
            goal: goal,
            context: context
        )

        let savedDays = try context.fetch(
            FetchDescriptor<LearningDay>()
        )

        // Only one record should exist
        #expect(savedDays.count == 1)
        #expect(savedDays.first?.type == .learned)
    }
    @Test
    @MainActor
    func cannotLearnAfterFreezeOnSameDay() throws {
        let container = try ModelContainer(
            for: LearningGoal.self, LearningDay.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let context = container.mainContext
        let viewModel = LearningGoalViewModel()

        let goal = LearningGoal(
            title: "Learn SwiftUI",
            duration: .week,
            startDate: Calendar.current.date(
                byAdding: .day,
                value: -2,
                to: .now
            )!
        )

        context.insert(goal)
        let yesterday = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: .now
        )!

        let previousLearningDay = LearningDay(
            date: yesterday,
            type: .learned,
            goal: goal
        )

        context.insert(previousLearningDay)

        viewModel.logDay(
            type: .frozen,
            goal: goal,
            context: context
        )

        viewModel.logDay(
            type: .learned,
            goal: goal,
            context: context
        )

        let savedDays = try context.fetch(
            FetchDescriptor<LearningDay>()
        )

        #expect(savedDays.count == 2)

        let today = savedDays.first {
            Calendar.current.isDateInToday($0.date)
        }

        #expect(today?.type == .frozen)
    }
    
    @Test
    @MainActor
    func cannotFreezeAfterWeeklyLimitReached() throws {
        let container = try ModelContainer(
            for: LearningGoal.self, LearningDay.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let context = container.mainContext
        let viewModel = LearningGoalViewModel()
        let calendar = Calendar.current

        let goal = LearningGoal(
            title: "Learn SwiftUI",
            duration: .week,
            startDate: calendar.date(
                byAdding: .day,
                value: -3,
                to: .now
            )!
        )

        context.insert(goal)

        // Two freezes on previous days
        for offset in [1, 2] {
            let date = calendar.date(
                byAdding: .day,
                value: -offset,
                to: .now
            )!

            let frozenDay = LearningDay(
                date: date,
                type: .frozen,
                goal: goal
            )

            context.insert(frozenDay)
        }

        // Attempt a third freeze today
        viewModel.logDay(
            type: .frozen,
            goal: goal,
            context: context
        )

        let savedDays = try context.fetch(
            FetchDescriptor<LearningDay>()
        )

        // Only the original two freezes should exist
        #expect(savedDays.count == 2)
        #expect(viewModel.usedFreezes(days: savedDays) == 2)

        // Today should not be frozen
        let todayIsFrozen = savedDays.contains {
            calendar.isDate($0.date, inSameDayAs: .now)
                && $0.type == .frozen
        }

        #expect(todayIsFrozen == false)
    }
    @Test
    @MainActor
    func newGoalCanLogOnSameDayAsPreviousGoal() throws {
        let container = try ModelContainer(
            for: LearningGoal.self, LearningDay.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let context = container.mainContext
        let viewModel = LearningGoalViewModel()

        let oldGoal = LearningGoal(
            title: "Old Goal",
            duration: .week,
            startDate: .now.addingTimeInterval(-3600)
        )

        oldGoal.isCompleted = true
        context.insert(oldGoal)

        viewModel.logDay(
            type: .learned,
            goal: oldGoal,
            context: context
        )

        let newGoal = LearningGoal(
            title: "New Goal",
            duration: .week,
            startDate: .now
        )

        context.insert(newGoal)

        viewModel.logDay(
            type: .learned,
            goal: newGoal,
            context: context
        )

        let days = try context.fetch(FetchDescriptor<LearningDay>())

        #expect(days.count == 2)
        #expect(days.filter {
            $0.goal?.persistentModelID == newGoal.persistentModelID
        }.count == 1)
    }

    @Test(arguments: [LearningDayType.learned, .frozen])
    @MainActor
    func sameButtonUndoesAndOtherButtonCanThenLog(first: LearningDayType) throws {
        let container = try ModelContainer(
            for: LearningGoal.self, LearningDay.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let viewModel = LearningGoalViewModel()
        let now = Date()
        let other: LearningDayType = first == .learned ? .frozen : .learned
        let goal = LearningGoal(title: "Test", duration: .week, startDate: now)
        context.insert(goal)

        viewModel.logDay(type: first, goal: goal, context: context, currentDate: now)
        viewModel.logDay(type: other, goal: goal, context: context, currentDate: now)
        var days = try context.fetch(FetchDescriptor<LearningDay>())
        #expect(days.count == 1)
        #expect(viewModel.activityType(on: now, days: days) == first)
        #expect(viewModel.usedFreezes(days: days) == (first == .frozen ? 1 : 0))
        #expect(viewModel.calculateStreak(days: days, currentDate: now) == (first == .learned ? 1 : 0))

        viewModel.logDay(type: first, goal: goal, context: context, currentDate: now)
        days = try context.fetch(FetchDescriptor<LearningDay>())
        #expect(days.isEmpty)
        #expect(viewModel.activityType(on: now, days: days) == nil)
        #expect(viewModel.calculateStreak(days: days, currentDate: now) == 0)
        #expect(viewModel.usedFreezes(days: days) == 0)

        viewModel.logDay(type: other, goal: goal, context: context, currentDate: now)
        days = try ModelContext(container).fetch(FetchDescriptor<LearningDay>())
        #expect(days.count == 1)
        #expect(viewModel.activityType(on: now, days: days) == other)
    }

    @Test
    @MainActor
    func undoAtFreezeLimitKeepsYesterdayAndRestoresAllowance() throws {
        let container = try ModelContainer(
            for: LearningGoal.self, LearningDay.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let viewModel = LearningGoalViewModel()
        let now = Date()
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: now))
        let goal = LearningGoal(title: "Test", duration: .week, startDate: yesterday)
        context.insert(goal)
        context.insert(LearningDay(date: yesterday, type: .frozen, goal: goal))

        viewModel.logDay(type: .frozen, goal: goal, context: context, currentDate: now)
        var days = try context.fetch(FetchDescriptor<LearningDay>())
        #expect(viewModel.usedFreezes(days: days) == 2)

        viewModel.logDay(type: .frozen, goal: goal, context: context, currentDate: now)
        days = try context.fetch(FetchDescriptor<LearningDay>())
        #expect(days.count == 1)
        #expect(days.first?.date == yesterday)
        #expect(viewModel.activityType(on: now, days: days) == nil)
        #expect(viewModel.canLogDay(type: .frozen, today: nil, freezesUsed: days.count, duration: .week))
    }

    @Test
    @MainActor
    func buttonAvailabilityFollowsTodayAndFreezeAllowance() {
        let viewModel = LearningGoalViewModel()
        #expect(viewModel.canLogDay(type: .learned, today: nil, freezesUsed: 0, duration: .week))
        #expect(viewModel.canLogDay(type: .frozen, today: nil, freezesUsed: 0, duration: .week))
        #expect(viewModel.canLogDay(type: .learned, today: .learned, freezesUsed: 0, duration: .week))
        #expect(!viewModel.canLogDay(type: .frozen, today: .learned, freezesUsed: 0, duration: .week))
        #expect(viewModel.canLogDay(type: .frozen, today: .frozen, freezesUsed: 2, duration: .week))
        #expect(!viewModel.canLogDay(type: .learned, today: .frozen, freezesUsed: 2, duration: .week))
        #expect(!viewModel.canLogDay(type: .frozen, today: nil, freezesUsed: 2, duration: .week))
        #expect(viewModel.canLogDay(type: .learned, today: nil, freezesUsed: 2, duration: .week))
    }
}

@MainActor
struct QAEdgeTests {
    @Test func goalCreationRejectsBlankAndRepeatedSubmission() throws {
        let container = try ModelContainer(for: LearningGoal.self, LearningDay.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let vm = LearningGoalViewModel()
        vm.saveGoal(title: "   ", duration: .week, context: context)
        #expect(try context.fetchCount(FetchDescriptor<LearningGoal>()) == 0)
        vm.saveGoal(title: " Swift ", duration: .month, context: context)
        vm.saveGoal(title: " Swift ", duration: .month, context: context)
        let goals = try ModelContext(container).fetch(FetchDescriptor<LearningGoal>())
        #expect(goals.count == 1)
        #expect(goals.first?.title == "Swift")
        #expect(goals.first?.duration == .month)
    }

    @Test func savedGoalSurvivesReopeningStoreAndPreservesHistory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = ModelConfiguration(url: directory.appendingPathComponent("QA.store"))
        let vm = LearningGoalViewModel()
        do {
            let store = try ModelContainer(for: LearningGoal.self, LearningDay.self, configurations: configuration)
            let context = store.mainContext
            let oldGoal = LearningGoal(title: "Archived", duration: .week, startDate: .distantPast)
            oldGoal.isCompleted = true
            context.insert(oldGoal)
            context.insert(LearningDay(date: .distantPast, type: .learned, goal: oldGoal))
            try context.save()
            #expect(vm.saveGoal(title: "Swift", duration: .year, context: context))
        }
        let reopened = try ModelContainer(for: LearningGoal.self, LearningDay.self, configurations: configuration)
        let goals = try reopened.mainContext.fetch(FetchDescriptor<LearningGoal>())
        let days = try reopened.mainContext.fetch(FetchDescriptor<LearningDay>())
        #expect(goals.count == 2)
        #expect(goals.first(where: { !$0.isCompleted })?.duration == .year)
        #expect(days.count == 1)
        #expect(days.first?.goal?.title == "Archived")
    }

    @Test(arguments: [LearningDuration.week, .month, .year])
    func exactDeadlineAndFreezeLimit(duration: LearningDuration) throws {
        let calendar = Calendar.current
        let now = Date()
        let vm = LearningGoalViewModel()
        let goal = LearningGoal(title: "QA", duration: duration, startDate: now)
        let end = try #require(vm.goalEndDate(for: goal))
        let count = try #require(calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: end)).day)
        let limit = vm.freezeLimit(for: duration)
        let days = try (0..<count).map { offset in
            LearningDay(date: try #require(calendar.date(byAdding: .day, value: offset, to: now)),
                        type: offset < limit ? .frozen : .learned, goal: goal)
        }
        #expect(vm.isGoalSuccessful(goal, days: days, currentDate: end.addingTimeInterval(-1)) == false)
        #expect(vm.isGoalSuccessful(goal, days: days, currentDate: end))
        #expect(vm.isGoalSuccessful(goal, days: days, currentDate: end.addingTimeInterval(1)))
        #expect(!vm.isGoalSuccessful(goal, days: Array(days.dropLast()), currentDate: end))
        #expect(vm.canLogDay(type: .frozen, today: nil, freezesUsed: limit - 1, duration: duration))
        #expect(!vm.canLogDay(type: .frozen, today: nil, freezesUsed: limit, duration: duration))
        #expect(!vm.canLogDay(type: .frozen, today: nil, freezesUsed: limit + 1, duration: duration))
    }
}
