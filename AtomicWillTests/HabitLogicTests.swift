//
//  HabitLogicTests.swift
//  AtomicWillTests
//

import Foundation
import SwiftData
import Testing
@testable import AtomicWill

@MainActor
struct HabitLogicTests {
    let container = Persistence.makeContainer(inMemory: true)
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2 // Monday
        return calendar
    }()

    var context: ModelContext { container.mainContext }

    /// A day in November 2026. Monday is November 23.
    func nov(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day))!
    }

    func makeRepeating(period: HabitPeriod, goal: GoalType, target: Int, minimum: Int = 0) -> Habit {
        let habit = Habit(name: "Habit", kind: .repeating, startDate: nov(1))
        habit.period = period
        habit.goalType = goal
        habit.targetCount = target
        habit.minimumCount = minimum
        context.insert(habit)
        return habit
    }

    // MARK: Goals

    @Test func atLeastGoalCountsExtras() {
        let sport = makeRepeating(period: .week, goal: .atLeast, target: 2)
        for day in [23, 24, 26] {
            sport.logCompletion(on: nov(day), calendar: calendar, in: context)
        }

        let progress = sport.progress(on: nov(29), today: nov(29), calendar: calendar)
        #expect(progress.count == 3)
        #expect(progress.status == .extra)
        #expect(progress.extraCount == 1)
        #expect(progress.completion == 1.5)
        #expect(progress.score == 1.5)
    }

    @Test func progressOnlyCountsUpToTheGivenDay() {
        let sport = makeRepeating(period: .week, goal: .atLeast, target: 2)
        sport.logCompletion(on: nov(23), calendar: calendar, in: context)
        sport.logCompletion(on: nov(25), calendar: calendar, in: context)

        #expect(sport.progress(on: nov(24), today: nov(29), calendar: calendar).status == .inProgress)
        #expect(sport.progress(on: nov(25), today: nov(29), calendar: calendar).status == .met)
    }

    @Test func weeksResetOnTheFirstWeekday() {
        let sport = makeRepeating(period: .week, goal: .atLeast, target: 1)
        sport.logCompletion(on: nov(22), calendar: calendar, in: context) // Sunday

        #expect(sport.progress(on: nov(22), today: nov(23), calendar: calendar).status == .met)
        #expect(sport.progress(on: nov(23), today: nov(23), calendar: calendar).count == 0)
    }

    @Test(arguments: [(0, HabitProgress.Status.inProgress), (1, .met), (2, .met), (3, .overLimit)])
    func limitGoal(count: Int, expected: HabitProgress.Status) {
        let coffee = makeRepeating(period: .week, goal: .limit, target: 2, minimum: 1)
        for _ in 0..<count {
            coffee.logCompletion(on: nov(24), calendar: calendar, in: context)
        }
        #expect(coffee.progress(on: nov(24), today: nov(24), calendar: calendar).status == expected)
    }

    @Test func limitWithoutMinimumIsMetWithNoCompletions() {
        let progress = HabitProgress.evaluate(count: 0, goalType: .limit, target: 2, minimum: 0)
        #expect(progress.status == .met)
        #expect(progress.score == 1)
    }

    @Test func undoRemovesOneCompletion() {
        let water = makeRepeating(period: .day, goal: .atLeast, target: 3)
        water.logCompletion(on: nov(23), calendar: calendar, in: context)
        water.logCompletion(on: nov(23), calendar: calendar, in: context)
        water.removeCompletion(on: nov(23), calendar: calendar, in: context)

        #expect(water.completionCount(on: nov(23), calendar: calendar) == 1)
    }

    // MARK: Scheduling

    @Test func dailyHabitFollowsWeekdays() {
        let gym = makeRepeating(period: .day, goal: .atLeast, target: 1)
        gym.weekdays = [2, 4] // Monday, Wednesday

        #expect(gym.isScheduled(on: nov(23), today: nov(23), calendar: calendar))
        #expect(!gym.isScheduled(on: nov(24), today: nov(23), calendar: calendar))
        #expect(gym.isScheduled(on: nov(25), today: nov(23), calendar: calendar))
    }

    @Test func archivedHabitKeepsHistory() {
        let habit = makeRepeating(period: .day, goal: .atLeast, target: 1)
        habit.archivedAt = nov(20)

        #expect(habit.isScheduled(on: nov(19), today: nov(23), calendar: calendar))
        #expect(!habit.isScheduled(on: nov(20), today: nov(23), calendar: calendar))
    }

    // MARK: One-time tasks

    @Test func openTaskCarriesOverUntilToday() {
        let task = Habit(name: "Dentist", kind: .oneTime, startDate: nov(20))
        context.insert(task)

        #expect(task.oneTimeState(on: nov(19), today: nov(23), calendar: calendar) == nil)
        #expect(task.oneTimeState(on: nov(20), today: nov(23), calendar: calendar) == .carriedOver)
        #expect(task.oneTimeState(on: nov(22), today: nov(23), calendar: calendar) == .carriedOver)
        #expect(task.oneTimeState(on: nov(23), today: nov(23), calendar: calendar) == .pending)
        #expect(task.oneTimeState(on: nov(24), today: nov(23), calendar: calendar) == nil)
    }

    @Test func futureTaskShowsOnlyOnItsDay() {
        let task = Habit(name: "Trip", kind: .oneTime, startDate: nov(28))
        context.insert(task)

        #expect(task.oneTimeState(on: nov(27), today: nov(23), calendar: calendar) == nil)
        #expect(task.oneTimeState(on: nov(28), today: nov(23), calendar: calendar) == .pending)
        #expect(task.oneTimeState(on: nov(29), today: nov(23), calendar: calendar) == nil)
    }

    @Test func notCompletedTaskStopsCarryingOver() {
        let task = Habit(name: "Call", kind: .oneTime, startDate: nov(20))
        context.insert(task)
        task.resolveTask(as: .notCompleted, on: nov(22), calendar: calendar)

        #expect(task.oneTimeState(on: nov(21), today: nov(23), calendar: calendar) == .carriedOver)
        #expect(task.oneTimeState(on: nov(22), today: nov(23), calendar: calendar) == .notCompleted)
        #expect(!task.isScheduled(on: nov(23), today: nov(23), calendar: calendar))
    }

    @Test func reopeningTaskCarriesItOverAgain() {
        let task = Habit(name: "Call", kind: .oneTime, startDate: nov(20))
        context.insert(task)
        task.resolveTask(as: .completed, on: nov(21), calendar: calendar)
        task.resolveTask(as: .pending, on: nov(21), calendar: calendar)

        #expect(task.oneTimeState(on: nov(23), today: nov(23), calendar: calendar) == .pending)
    }

    // MARK: Summary rings

    @Test func summaryCombinesEverythingIntoOneRing() {
        let read = makeRepeating(period: .day, goal: .atLeast, target: 1)
        read.logCompletion(on: nov(23), calendar: calendar, in: context)
        let sport = makeRepeating(period: .week, goal: .atLeast, target: 2)
        sport.logCompletion(on: nov(23), calendar: calendar, in: context)
        let carried = Habit(name: "Old task", kind: .oneTime, startDate: nov(20))
        context.insert(carried)

        let pastSummary = DaySummary.make(for: nov(21), habits: [read, sport, carried], today: nov(23), calendar: calendar)
        #expect(pastSummary.tasks == nil) // Carried-over days don't count.

        // Read is done, Sport is ahead of pace on Monday, the task is open.
        let summary = DaySummary.make(for: nov(23), habits: [read, sport, carried], today: nov(23), calendar: calendar)
        #expect(summary.daily == 1)
        #expect(summary.goals == 1)
        #expect(summary.tasks == 0)
        #expect(abs((summary.progress ?? 0) - 2.0 / 3.0) < 0.0001)
        #expect(!summary.isComplete)
    }

    @Test func extrasOnlyAddALapOnceEverythingIsDone() {
        #expect(DaySummary.combined([2, 0]) == 0.5)
        #expect(DaySummary.combined([2, 1]) == 1.5)
        #expect(DaySummary.combined([]) == nil)
    }

    // MARK: Pace

    @Test func weeklyGoalIsScoredByPace() {
        let sport = makeRepeating(period: .week, goal: .atLeast, target: 2)

        // Nothing done yet: Monday barely counts against you, Sunday counts fully.
        let monday = sport.progress(on: nov(23), today: nov(29), calendar: calendar)
        #expect(abs(monday.score - (1 - 2.0 / 7.0 / 2.0)) < 0.0001)
        #expect(sport.progress(on: nov(29), today: nov(29), calendar: calendar).score == 0)

        // One completion by Wednesday is on pace; finishing the week at 1 of 2 scores half.
        sport.logCompletion(on: nov(24), calendar: calendar, in: context)
        let wednesday = sport.progress(on: nov(25), today: nov(29), calendar: calendar)
        #expect(wednesday.isOnPace)
        #expect(wednesday.score == 1)
        #expect(sport.progress(on: nov(29), today: nov(29), calendar: calendar).score == 0.5)
    }

    @Test func dailyGoalIsNotAffectedByPace() {
        let water = makeRepeating(period: .day, goal: .atLeast, target: 4)
        water.logCompletion(on: nov(23), calendar: calendar, in: context)
        #expect(water.progress(on: nov(23), today: nov(23), calendar: calendar).score == 0.25)
    }

    @Test func brokenLimitIsReported() {
        let coffee = makeRepeating(period: .week, goal: .limit, target: 1)
        coffee.logCompletion(on: nov(23), calendar: calendar, in: context)
        coffee.logCompletion(on: nov(24), calendar: calendar, in: context)

        let summary = DaySummary.make(for: nov(24), habits: [coffee], today: nov(24), calendar: calendar)
        #expect(summary.hasBrokenLimit)
        #expect(summary.goals == 0)
    }
}
