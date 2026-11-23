//
//  HabitScheduling.swift
//  AtomicWill
//

import Foundation
import SwiftData

/// How a one-time task appears on a given day.
nonisolated enum OneTimeDayState: Equatable {
    /// Scheduled for this day (or carried into today) and not done yet.
    case pending
    /// Was open on this past day and rolled over to the next one.
    case carriedOver
    case completed
    case notCompleted
}

/// Progress of a habit for the period that contains a given day.
nonisolated struct HabitProgress: Equatable {
    enum Status: Equatable {
        case inProgress
        case met
        /// An at-least goal that was completed more often than its target.
        case extra
        /// A limit goal that went over its ceiling, so the goal is broken.
        case overLimit
    }

    var count: Int
    var status: Status
    /// How far the period's goal is completed, for a habit's own ring. Above 1 with extras.
    var completion: Double
    /// Contribution to the day's ring, judged by pace. Above 1 only with extras.
    var score: Double
    var extraCount: Int = 0

    var isSuccessful: Bool { status == .met || status == .extra }

    /// A weekly or monthly goal that isn't met yet, but is where it should be for this point in the period.
    var isOnPace: Bool { status == .inProgress && score >= 1 }

    /// Evaluates `count` completions against a goal.
    ///
    /// - Parameter periodElapsed: How much of the goal's period has passed by the end of the day
    ///   being scored, from 0 to 1. Daily goals always pass 1.
    ///
    /// The score compares the count with what's expected by now (`goal × periodElapsed`). Falling behind
    /// lowers the score by the shortfall relative to the whole goal, so missing Monday on a twice-a-week
    /// habit barely dents the ring, while ending the week at 1 of 2 scores 50%.
    static func evaluate(
        count: Int,
        goalType: GoalType,
        target: Int,
        minimum: Int,
        periodElapsed: Double = 1
    ) -> HabitProgress {
        let elapsed = min(max(periodElapsed, 0), 1)

        func paceScore(goal: Int) -> Double {
            guard goal > 0 else { return 1 }
            let expected = Double(goal) * elapsed
            let shortfall = max(expected - Double(count), 0)
            return max(1 - shortfall / Double(goal), 0)
        }

        switch goalType {
        case .atLeast:
            let target = max(target, 1)
            let completion = Double(count) / Double(target)
            if count > target {
                return HabitProgress(
                    count: count, status: .extra, completion: completion, score: completion, extraCount: count - target
                )
            }
            let status: Status = count == target ? .met : .inProgress
            return HabitProgress(count: count, status: status, completion: completion, score: paceScore(goal: target))

        case .limit:
            let maximum = max(target, 1)
            let minimum = min(max(minimum, 0), maximum)
            if count > maximum {
                return HabitProgress(count: count, status: .overLimit, completion: 1, score: 0)
            }
            if count >= minimum {
                return HabitProgress(count: count, status: .met, completion: 1, score: 1)
            }
            return HabitProgress(
                count: count,
                status: .inProgress,
                completion: Double(count) / Double(minimum),
                score: paceScore(goal: minimum)
            )
        }
    }
}

// MARK: - Scheduling

extension Habit {
    var completionList: [HabitCompletion] { completions ?? [] }

    /// Whether the habit belongs in the list for `day`.
    func isScheduled(on day: Date, today: Date, calendar: Calendar) -> Bool {
        let day = calendar.startOfDay(for: day)
        guard day >= calendar.startOfDay(for: startDate) else { return false }
        if let archivedAt, day >= calendar.startOfDay(for: archivedAt) {
            return false
        }

        switch kind {
        case .oneTime:
            return oneTimeState(on: day, today: today, calendar: calendar) != nil
        case .repeating:
            if period == .day, !weekdays.isEmpty {
                return weekdays.contains(calendar.component(.weekday, from: day))
            }
            return true
        }
    }

    /// The state of a one-time task on `day`, or `nil` if the task doesn't appear that day.
    ///
    /// An open task shows on its scheduled day. Once that day is past, it carries over to every day
    /// up to today, until it's completed or marked as not completed.
    func oneTimeState(on day: Date, today: Date, calendar: Calendar) -> OneTimeDayState? {
        guard kind == .oneTime else { return nil }
        let day = calendar.startOfDay(for: day)
        let start = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: today)
        guard day >= start else { return nil }

        switch taskStatus {
        case .pending:
            if day < today { return .carriedOver }
            if day == today { return .pending }
            return day == start ? .pending : nil

        case .completed, .notCompleted:
            let resolved = max(calendar.startOfDay(for: resolvedDate ?? startDate), start)
            if day < resolved { return .carriedOver }
            if day == resolved { return taskStatus == .completed ? .completed : .notCompleted }
            return nil
        }
    }

    /// The goal period (day, week, or month) that contains `day`.
    func periodInterval(containing day: Date, calendar: Calendar) -> DateInterval {
        calendar.dateInterval(of: period.calendarComponent, for: day)
            ?? DateInterval(start: calendar.startOfDay(for: day), duration: 86_400)
    }

    func completionCount(from start: Date, to end: Date) -> Int {
        completionList.reduce(0) { count, completion in
            completion.day >= start && completion.day < end ? count + 1 : count
        }
    }

    /// Completions logged on exactly `day`.
    func completionCount(on day: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: day)
        return completionCount(from: start, to: calendar.endOfDay(for: start))
    }

    /// Progress for the period containing `day`, counting completions up to the end of that day.
    func progress(on day: Date, today: Date, calendar: Calendar) -> HabitProgress {
        switch kind {
        case .oneTime:
            let done = oneTimeState(on: day, today: today, calendar: calendar) == .completed
            let value: Double = done ? 1 : 0
            return HabitProgress(count: done ? 1 : 0, status: done ? .met : .inProgress, completion: value, score: value)

        case .repeating:
            let interval = periodInterval(containing: day, calendar: calendar)
            let end = min(interval.end, calendar.endOfDay(for: day))
            let count = completionCount(from: interval.start, to: end)
            return .evaluate(
                count: count,
                goalType: goalType,
                target: targetCount,
                minimum: minimumCount,
                periodElapsed: Self.fraction(of: interval, elapsedBy: end, calendar: calendar)
            )
        }
    }

    /// The share of whole days in `interval` that have passed by `end`.
    private static func fraction(of interval: DateInterval, elapsedBy end: Date, calendar: Calendar) -> Double {
        let total = calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 1
        let elapsed = calendar.dateComponents([.day], from: interval.start, to: end).day ?? total
        return total > 0 ? Double(elapsed) / Double(total) : 1
    }
}

// MARK: - Mutations

extension Habit {
    func logCompletion(on day: Date, calendar: Calendar, in context: ModelContext) {
        let completion = HabitCompletion(day: calendar.startOfDay(for: day))
        context.insert(completion)
        completion.habit = self
    }

    /// Removes the most recent completion logged on `day`, if there is one.
    func removeCompletion(on day: Date, calendar: Calendar, in context: ModelContext) {
        let start = calendar.startOfDay(for: day)
        let end = calendar.endOfDay(for: start)
        let candidates = completionList.filter { $0.day >= start && $0.day < end }
        guard let latest = candidates.max(by: { $0.loggedAt < $1.loggedAt }) else { return }
        completions?.removeAll { $0.persistentModelID == latest.persistentModelID }
        context.delete(latest)
    }

    func resolveTask(as status: TaskStatus, on day: Date, calendar: Calendar) {
        taskStatus = status
        resolvedDate = status == .pending ? nil : calendar.startOfDay(for: day)
    }
}

// MARK: - Day summary

/// The day's single ring, plus a breakdown by category. `nil` means nothing of that kind is scheduled.
nonisolated struct DaySummary: Equatable {
    /// The ring value. Reaches 1 when everything is done or on pace, and only goes past 1 with extras.
    var progress: Double?
    var daily: Double?
    var goals: Double?
    var tasks: Double?
    /// Whether any limit habit went over its ceiling.
    var hasBrokenLimit = false

    var isEmpty: Bool { progress == nil }

    /// The ring is closed.
    var isComplete: Bool { (progress ?? 0) >= 0.999 }

    func value(for category: SummaryCategory) -> Double? {
        switch category {
        case .daily: daily
        case .goals: goals
        case .tasks: tasks
        }
    }

    static func make(for day: Date, habits: [Habit], today: Date, calendar: Calendar) -> DaySummary {
        var daily: [Double] = []
        var goals: [Double] = []
        var tasks: [Double] = []
        var hasBrokenLimit = false

        for habit in habits where habit.isScheduled(on: day, today: today, calendar: calendar) {
            switch habit.kind {
            case .oneTime:
                // Carried-over days don't count against the ring; the task counts on the day it's open or resolved.
                guard let state = habit.oneTimeState(on: day, today: today, calendar: calendar),
                      state != .carriedOver else { continue }
                tasks.append(state == .completed ? 1 : 0)

            case .repeating:
                let progress = habit.progress(on: day, today: today, calendar: calendar)
                if progress.status == .overLimit { hasBrokenLimit = true }
                if habit.period == .day {
                    daily.append(progress.score)
                } else {
                    goals.append(progress.score)
                }
            }
        }

        return DaySummary(
            progress: combined(daily + goals + tasks),
            daily: combined(daily),
            goals: combined(goals),
            tasks: combined(tasks),
            hasBrokenLimit: hasBrokenLimit
        )
    }

    /// Averages scores with each one capped at 1, so an extra on one habit can't hide a missed one.
    /// Once everything is complete, extras push the value past 1 for the second lap.
    static func combined(_ scores: [Double]) -> Double? {
        guard !scores.isEmpty else { return nil }
        let count = Double(scores.count)
        let base = scores.reduce(0) { $0 + min($1, 1) } / count
        guard base >= 0.999 else { return base }
        let bonus = scores.reduce(0) { $0 + max($1 - 1, 0) } / count
        return 1 + bonus
    }
}

// MARK: - Calendar helpers

nonisolated extension Calendar {
    func endOfDay(for date: Date) -> Date {
        let start = startOfDay(for: date)
        return self.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
    }

    /// Weekday numbers (1 = Sunday) in display order, starting at the locale's first weekday.
    var orderedWeekdays: [Int] {
        (0..<7).map { (firstWeekday - 1 + $0) % 7 + 1 }
    }

    /// Every day in the month that contains `date`.
    func days(inMonthOf date: Date) -> [Date] {
        guard let interval = dateInterval(of: .month, for: date) else { return [] }
        var days: [Date] = []
        var day = interval.start
        while day < interval.end {
            days.append(day)
            guard let next = self.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }
}
