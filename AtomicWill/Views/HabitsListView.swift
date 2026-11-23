//
//  HabitsListView.swift
//  AtomicWill
//

import SwiftUI
import SwiftData

/// Every habit and task, for managing them outside of a specific day.
struct HabitsListView: View {
    let today: Date

    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)])
    private var habits: [Habit]

    @Environment(\.modelContext) private var modelContext
    @State private var editingHabit: Habit?
    @State private var isAddingHabit = false
    @State private var habitPendingDeletion: Habit?

    var body: some View {
        let active = habits.filter { !$0.isArchived }

        NavigationStack {
            List {
                section("Repeating", habits: active.filter { $0.kind == .repeating })
                section("One-Time", habits: active.filter { $0.kind == .oneTime })
                section("Archived", habits: habits.filter(\.isArchived))
            }
            .overlay {
                if habits.isEmpty {
                    ContentUnavailableView(
                        "No Habits",
                        systemImage: "square.stack.3d.up",
                        description: Text("Tap the add button to create your first habit.")
                    )
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Habit", systemImage: "plus") { isAddingHabit = true }
                }
            }
            .sheet(isPresented: $isAddingHabit) {
                HabitEditorView(defaultDate: today)
            }
            .sheet(item: $editingHabit) { habit in
                HabitEditorView(habit: habit)
            }
            .confirmationDialog(
                "Delete Habit?",
                item: $habitPendingDeletion,
                titleVisibility: .visible
            ) { habit in
                Button("Delete \(habit.name)", role: .destructive) {
                    withAnimation { modelContext.delete(habit) }
                }
            } message: { _ in
                Text("This also deletes its history.")
            }
        }
    }

    @ViewBuilder
    private func section(_ title: LocalizedStringKey, habits: [Habit]) -> some View {
        if !habits.isEmpty {
            Section(title) {
                ForEach(habits) { habit in
                    Button {
                        editingHabit = habit
                    } label: {
                        HabitSummaryRow(habit: habit)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            habitPendingDeletion = habit
                        }
                        archiveButton(for: habit)
                    }
                    .contextMenu {
                        Button("Edit", systemImage: "pencil") { editingHabit = habit }
                        archiveButton(for: habit)
                        Divider()
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            habitPendingDeletion = habit
                        }
                    }
                }
            }
        }
    }

    private func archiveButton(for habit: Habit) -> some View {
        Button(
            habit.isArchived ? "Unarchive" : "Archive",
            systemImage: habit.isArchived ? "tray.and.arrow.up" : "archivebox"
        ) {
            withAnimation { habit.archivedAt = habit.isArchived ? nil : today }
        }
        .tint(.indigo)
    }
}

private struct HabitSummaryRow: View {
    let habit: Habit

    var body: some View {
        HStack(spacing: 12) {
            HabitIcon(habit: habit)
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.body.weight(.medium))
                Text(habit.scheduleDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .contentShape(.rect)
    }
}

extension Habit {
    /// A short description, for example "At least 2 per week" or "Nov 24 · Completed".
    var scheduleDescription: String {
        switch kind {
        case .oneTime:
            let date = startDate.formatted(.dateTime.month(.abbreviated).day())
            switch taskStatus {
            case .pending: return String(localized: "\(date) · Open")
            case .completed: return String(localized: "\(date) · Completed")
            case .notCompleted: return String(localized: "\(date) · Not completed")
            }

        case .repeating:
            let per = String(localized: period.perTitle)
            switch goalType {
            case .atLeast:
                return String(localized: "At least \(targetCount) \(per)")
            case .limit:
                if minimumCount > 0 {
                    return String(localized: "\(minimumCount) to \(targetCount) \(per)")
                }
                return String(localized: "At most \(targetCount) \(per)")
            }
        }
    }
}

#Preview(traits: .sampleData) {
    HabitsListView(today: .now)
}
