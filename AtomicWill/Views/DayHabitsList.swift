//
//  DayHabitsList.swift
//  AtomicWill
//

import SwiftUI
import SwiftData

/// Lists everything scheduled on one day, grouped by type, under a custom header.
struct DayHabitsList<Header: View>: View {
    let day: Date
    let today: Date
    @ViewBuilder var header: Header

    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)])
    private var habits: [Habit]

    @Environment(\.calendar) private var calendar
    @State private var editingHabit: Habit?

    var body: some View {
        let scheduled = habits.filter { $0.isScheduled(on: day, today: today, calendar: calendar) }
        let tasks = scheduled.filter { $0.kind == .oneTime }
        let repeating = scheduled.filter { $0.kind == .repeating }

        List {
            header

            if scheduled.isEmpty {
                Section {
                    ContentUnavailableView(
                        "Nothing Scheduled",
                        systemImage: "sparkles",
                        description: Text("Habits and tasks for this day show up here.")
                    )
                }
            }

            section("Tasks", habits: tasks)
            section("Daily", habits: repeating.filter { $0.period == .day })
            section("Weekly", habits: repeating.filter { $0.period == .week })
            section("Monthly", habits: repeating.filter { $0.period == .month })
        }
        .sheet(item: $editingHabit) { habit in
            HabitEditorView(habit: habit)
        }
    }

    @ViewBuilder
    private func section(_ title: LocalizedStringKey, habits: [Habit]) -> some View {
        if !habits.isEmpty {
            Section(title) {
                ForEach(habits) { habit in
                    HabitRowView(habit: habit, day: day, today: today) {
                        editingHabit = habit
                    }
                }
            }
        }
    }
}
