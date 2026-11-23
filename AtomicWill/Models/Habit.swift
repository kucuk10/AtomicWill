//
//  Habit.swift
//  AtomicWill
//

import Foundation
import SwiftData

/// A habit is either a one-time task or a repeating habit with a goal per period.
///
/// The model is kept CloudKit compatible so iCloud sync can be switched on later:
/// every attribute has a default value, relationships are optional, and nothing
/// uses unique constraints.
@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var symbolName: String = "checkmark.circle"
    var colorName: String = HabitColor.blue.rawValue
    var notes: String = ""
    var kindRaw: String = HabitKind.repeating.rawValue
    var createdAt: Date = Date.now
    var sortOrder: Int = 0

    /// For one-time tasks this is the scheduled day. For repeating habits it is the first active day.
    var startDate: Date = Date.now

    /// Archived habits stop showing up from this day on, but their history is kept.
    var archivedAt: Date?

    // MARK: Repeating habits

    var periodRaw: String = HabitPeriod.week.rawValue
    var goalTypeRaw: String = GoalType.atLeast.rawValue

    /// For `.atLeast`, how many completions the period needs.
    /// For `.limit`, the most completions allowed in the period.
    var targetCount: Int = 1

    /// The fewest completions that still count as success. Only used by `.limit` goals.
    var minimumCount: Int = 0

    /// Weekdays (`Calendar` weekday numbers, 1 = Sunday) a daily habit is scheduled on.
    /// An empty array means every day.
    var weekdays: [Int] = []

    // MARK: One-time tasks

    var taskStatusRaw: String = TaskStatus.pending.rawValue

    /// The day a one-time task was completed or marked as not completed.
    var resolvedDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]? = []

    init(
        name: String,
        kind: HabitKind,
        startDate: Date = .now,
        symbolName: String = "checkmark.circle",
        color: HabitColor = .blue
    ) {
        self.name = name
        self.kindRaw = kind.rawValue
        self.startDate = startDate
        self.symbolName = symbolName
        self.colorName = color.rawValue
    }
}

/// A single completion of a habit, logged against a calendar day.
@Model
final class HabitCompletion {
    var id: UUID = UUID()
    /// The start of the day this completion counts for.
    var day: Date = Date.now
    var loggedAt: Date = Date.now
    var habit: Habit?

    init(day: Date) {
        self.day = day
    }
}

// MARK: - Supporting types

nonisolated enum HabitKind: String, CaseIterable, Identifiable {
    case oneTime
    case repeating

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .oneTime: "One-Time"
        case .repeating: "Repeating"
        }
    }
}

nonisolated enum HabitPeriod: String, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: Self { self }

    var calendarComponent: Calendar.Component {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .day: "Daily"
        case .week: "Weekly"
        case .month: "Monthly"
        }
    }

    var perTitle: LocalizedStringResource {
        switch self {
        case .day: "per day"
        case .week: "per week"
        case .month: "per month"
        }
    }
}

nonisolated enum GoalType: String, CaseIterable, Identifiable {
    /// Complete at least `targetCount` times. Anything above that counts as extra.
    case atLeast
    /// Complete between `minimumCount` and `targetCount` times. Going above the limit breaks the goal.
    case limit

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .atLeast: "Target"
        case .limit: "Limit"
        }
    }
}

nonisolated enum TaskStatus: String {
    case pending
    case completed
    case notCompleted
}

// MARK: - Typed accessors

extension Habit {
    var kind: HabitKind {
        get { HabitKind(rawValue: kindRaw) ?? .repeating }
        set { kindRaw = newValue.rawValue }
    }

    var period: HabitPeriod {
        get { HabitPeriod(rawValue: periodRaw) ?? .week }
        set { periodRaw = newValue.rawValue }
    }

    var goalType: GoalType {
        get { GoalType(rawValue: goalTypeRaw) ?? .atLeast }
        set { goalTypeRaw = newValue.rawValue }
    }

    var taskStatus: TaskStatus {
        get { TaskStatus(rawValue: taskStatusRaw) ?? .pending }
        set { taskStatusRaw = newValue.rawValue }
    }

    var habitColor: HabitColor {
        get { HabitColor(rawValue: colorName) ?? .blue }
        set { colorName = newValue.rawValue }
    }

    var isArchived: Bool { archivedAt != nil }
}
