//
//  CalendarScreen.swift
//  AtomicWill
//

import SwiftUI
import SwiftData

struct CalendarScreen: View {
    let today: Date

    @Query private var habits: [Habit]
    @Environment(\.calendar) private var calendar
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    @State private var displayedMonth = Date.now
    @State private var selectedDay = Date.now
    @State private var isAddingHabit = false

    /// Side-by-side month and day list when there's room; stacked otherwise.
    private var isWide: Bool {
        #if os(iOS)
        horizontalSizeClass == .regular
        #else
        true
        #endif
    }

    var body: some View {
        NavigationStack {
            Group {
                if isWide {
                    HStack(alignment: .top, spacing: 0) {
                        ScrollView {
                            monthView
                                .padding()
                        }
                        .frame(minWidth: 320, idealWidth: 420, maxWidth: 520)

                        Divider()

                        DayHabitsList(day: selectedDay, today: today) {
                            Section { selectedDayHeader }
                        }
                    }
                } else {
                    DayHabitsList(day: selectedDay, today: today) {
                        Section { monthView }
                        Section { selectedDayHeader }
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Habit", systemImage: "plus") { isAddingHabit = true }
                }
                ToolbarItem {
                    Button("Today") {
                        withAnimation {
                            displayedMonth = today
                            selectedDay = today
                        }
                    }
                    .keyboardShortcut("t")
                    .disabled(calendar.isDate(selectedDay, inSameDayAs: today))
                }
            }
            .sheet(isPresented: $isAddingHabit) {
                HabitEditorView(defaultDate: max(selectedDay, today))
            }
        }
    }

    private var monthView: some View {
        MonthView(
            month: $displayedMonth,
            selectedDay: $selectedDay,
            habits: habits,
            today: today
        )
    }

    private var selectedDayHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(selectedDay, format: .dateTime.weekday(.wide).month(.wide).day().year())
                .font(.headline)
            DaySummaryHeader(
                summary: DaySummary.make(for: selectedDay, habits: habits, today: today, calendar: calendar)
            )
        }
    }
}

/// A month grid where each day shows small summary rings.
struct MonthView: View {
    @Binding var month: Date
    @Binding var selectedDay: Date
    let habits: [Habit]
    let today: Date

    @Environment(\.calendar) private var calendar

    private struct Cell: Identifiable {
        let id: Int
        let day: Date?
    }

    private var cells: [Cell] {
        let days = calendar.days(inMonthOf: month)
        guard let first = days.first else { return [] }
        let leading = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
        let blanks = (0..<leading).map { Cell(id: -1 - $0, day: nil) }
        let dayCells = days.enumerated().map { Cell(id: $0.offset, day: $0.element) }
        return blanks + dayCells
    }

    var body: some View {
        let monthDays = calendar.days(inMonthOf: month)
        let summaries = Dictionary(uniqueKeysWithValues: monthDays.map {
            ($0, DaySummary.make(for: $0, habits: habits, today: today, calendar: calendar))
        })

        VStack(spacing: 12) {
            header

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(calendar.orderedWeekdays, id: \.self) { weekday in
                    Text(calendar.veryShortStandaloneWeekdaySymbols[weekday - 1])
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }

                ForEach(cells) { cell in
                    if let day = cell.day {
                        DayCell(
                            day: day,
                            summary: day > today ? DaySummary() : summaries[day] ?? DaySummary(),
                            isToday: calendar.isDate(day, inSameDayAs: today),
                            isSelected: calendar.isDate(day, inSameDayAs: selectedDay),
                            isFuture: day > today
                        )
                        .onTapGesture { selectedDay = day }
                        .accessibilityAddTraits(.isButton)
                    } else {
                        Color.clear.frame(height: 1)
                    }
                }
            }

            stats(summaries: monthDays.compactMap { $0 <= today ? summaries[$0] : nil })
        }
    }

    private var header: some View {
        HStack {
            Text(month, format: .dateTime.month(.wide).year())
                .font(.title2.weight(.bold))
            Spacer()
            Button("Previous Month", systemImage: "chevron.left") { shiftMonth(by: -1) }
                .keyboardShortcut(.leftArrow, modifiers: .command)
            Button("Next Month", systemImage: "chevron.right") { shiftMonth(by: 1) }
                .keyboardShortcut(.rightArrow, modifiers: .command)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .font(.title3)
    }

    private func stats(summaries: [DaySummary]) -> some View {
        let tracked = summaries.filter { !$0.isEmpty }
        let perfect = tracked.filter(\.isComplete).count
        return HStack {
            Label("\(perfect) of \(tracked.count) days with the ring closed", systemImage: "trophy.fill")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func shiftMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: month) else { return }
        withAnimation { month = newMonth }
    }
}

private struct DayCell: View {
    let day: Date
    let summary: DaySummary
    let isToday: Bool
    let isSelected: Bool
    let isFuture: Bool

    @Environment(\.calendar) private var calendar

    var body: some View {
        DayRingView(summary: summary, thickness: 0.11) {
            Text(calendar.component(.day, from: day), format: .number)
                .font(.callout.weight(isToday ? .bold : .medium).monospacedDigit())
                .foregroundStyle(isToday ? Color.dayRing : isFuture ? .secondary : .primary)
                .minimumScaleFactor(0.6)
        }
        .opacity(isFuture ? 0.55 : 1)
        .padding(4)
        .frame(maxWidth: .infinity)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 10).fill(.tint.opacity(0.15))
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(day, format: .dateTime.weekday(.wide).month(.wide).day()))
        .accessibilityValue(Text(summary.accessibilityDescription))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview(traits: .sampleData) {
    CalendarScreen(today: .now)
}
