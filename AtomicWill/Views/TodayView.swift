//
//  TodayView.swift
//  AtomicWill
//

import SwiftUI
import SwiftData

struct TodayView: View {
    let today: Date

    @Query private var habits: [Habit]
    @Environment(\.calendar) private var calendar
    @State private var isAddingHabit = false

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView {
                        Label("No Habits Yet", systemImage: "checklist")
                    } description: {
                        Text("Add a one-time task or a repeating habit to get started.")
                    } actions: {
                        Button("New Habit") { isAddingHabit = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    DayHabitsList(day: today, today: today) {
                        Section {
                            DaySummaryHeader(
                                summary: DaySummary.make(for: today, habits: habits, today: today, calendar: calendar)
                            )
                        }
                    }
                }
            }
            .navigationTitle("Today")
            .navigationSubtitle(Text(today, format: .dateTime.weekday(.wide).month(.wide).day()))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Habit", systemImage: "plus") { isAddingHabit = true }
                        .keyboardShortcut("n")
                }
            }
            .sheet(isPresented: $isAddingHabit) {
                HabitEditorView(defaultDate: today)
            }
        }
    }
}

#Preview(traits: .sampleData) {
    TodayView(today: .now)
}
