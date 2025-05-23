//
//  CalendarHabitsView.swift
//  AtomicWill
//
//  Created by Caner Kucuk on 5/23/25.
//
// CalendarHabitsView.swift
import SwiftUI
import SwiftData

// CalendarScope and CalendarDay are expected to be in CalendarModels.swift

struct CalendarHabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var calendarScope: CalendarScope = .month

    @Query(sort: [SortDescriptor(\HabitLog.completionDate, order: .forward)])
    private var allHabitLogs: [HabitLog]

    private var calendar = Calendar.current

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Scope", selection: $calendarScope) {
                    ForEach(CalendarScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])

                calendarHeader
                    .padding(.bottom, 10)

                if calendarScope == .month {
                    weekdayHeaderRow
                        .padding(.horizontal, 5)
                }

                if calendarScope == .month {
                    monthGridView
                } else {
                    weekStripView
                    detailedDayViewPlaceholder
                }
                Spacer()
            }
            .navigationTitle("Calendar")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Today") {
                        selectedDate = Calendar.current.startOfDay(for: Date())
                    }
                }
            }
        }
    }

    // MARK: - Sub-component Views

    private var calendarHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Button { changeDate(by: -1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(currentHeaderTitle)
                    .font(.title2.bold())
                Spacer()
                Button { changeDate(by: 1) } label: { Image(systemName: "chevron.right") }
            }
            .padding(.horizontal)
        }
    }

    private var weekdayHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(calendar.veryShortWeekdaySymbolsOrdered, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 4)
    }

    private var monthGridView: some View {
        let daysInGrid = generateDaysInMonth(for: selectedDate)
        let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(daysInGrid) { day in
                    dayCell(for: day)
                        .border(Color(uiColor: .separator), width: 0.5)
                        .onTapGesture {
                            if day.isCurrentMonth {
                                print("Tapped Month Day: \(day.date)")
                            }
                        }
                }
            }
        }
        .padding(.horizontal, 0.5)
    }
    
    @ViewBuilder
    private func dayCell(for day: CalendarDay) -> some View {
        let habitsOnDay = getCompletedHabitsForDay(day.date)
        VStack(spacing: 2) {
            Text(day.dayNumber)
                .font(.system(size: 15))
                .fontWeight(day.isToday ? .bold : (day.isCurrentMonth ? .medium : .regular))
                .foregroundColor(dayCellForegroundColor(for: day))
                .frame(width: 28, height: 28)
                .background(dayCellBackgroundColor(for: day))
                .clipShape(Circle())
                .padding(.top, 4)

            HStack(spacing: 2) {
                ForEach(habitsOnDay.prefix(4)) { habit in
                    Circle()
                        .fill(Color(hex: habit.colorHex) ?? .gray)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 10)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 60, idealHeight: 70)
        .frame(maxWidth: .infinity)
        .opacity(day.isCurrentMonth ? 1.0 : 0.4)
    }

    private var weekStripView: some View {
        let daysInCurrentWeek = generateDaysInWeek(for: selectedDate)
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(daysInCurrentWeek) { day in
                    weekDayCell(for: day, isSelectedInStrip: calendar.isDate(selectedDate, inSameDayAs: day.date))
                        .onTapGesture {
                            selectedDate = calendar.startOfDay(for: day.date)
                            print("Tapped Week Day: \(selectedDate)")
                        }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 90)
    }
    
    @ViewBuilder
    private func weekDayCell(for day: CalendarDay, isSelectedInStrip: Bool) -> some View {
        let habitsOnDay = getCompletedHabitsForDay(day.date)
        VStack(spacing: 4) {
            Text(calendar.veryShortWeekdaySymbolsOrdered[calendar.component(.weekday, from: day.date)-1])
                .font(.caption)
                .foregroundColor(isSelectedInStrip ? .red : .secondary)

            Text(day.dayNumber)
                .font(.title3)
                .fontWeight(isSelectedInStrip ? .bold : .regular)
                .foregroundColor(weekDayCellForegroundColor(for: day, isSelected: isSelectedInStrip))
                .frame(width: 36, height: 36)
                .background(weekDayCellBackgroundColor(for: day, isSelected: isSelectedInStrip))
                .clipShape(Circle())
            
            if !habitsOnDay.isEmpty {
                Circle().fill(weekDayDotColor(for: day, isSelected: isSelectedInStrip))
                    .frame(width: 5, height: 5)
                    .opacity(day.isToday && !isSelectedInStrip ? 0 : 1)
            } else {
                Circle().fill(.clear).frame(width: 5, height: 5)
            }
        }
        .padding(.vertical, 8)
    }

    private var detailedDayViewPlaceholder: some View {
        VStack {
            Text("Details for \(selectedDate.formatted(date: .complete, time: .omitted))")
                .font(.headline)
                .padding()
            Text("Timeline or list of habits for this day would go here.")
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Functions & Computed Properties

    private var currentHeaderTitle: String {
        let formatter = DateFormatter()
        if calendarScope == .month {
            formatter.dateFormat = "MMMM yyyy"
        } else {
            formatter.dateFormat = "MMMM yyyy"
        }
        return formatter.string(from: selectedDate)
    }

    private func changeDate(by value: Int) {
        let component: Calendar.Component = (calendarScope == .month) ? .month : .weekOfYear
        if let newDate = calendar.date(byAdding: component, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func generateDaysInMonth(for referenceDate: Date) -> [CalendarDay] {
        // CORRECTED GUARD for monthInterval and firstOfMonth
        guard let monthInterval = calendar.dateInterval(of: .month, for: referenceDate) else {
            print("Error: Could not get monthInterval for \(referenceDate)")
            return []
        }
        let firstOfMonth = monthInterval.start // Now non-optional

        var days: [CalendarDay] = []
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let daysToSubtract = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        guard let gridStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstOfMonth) else { return [] }

        for dayOffset in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: gridStartDate) {
                let isCurrentMonthFlag = calendar.isDate(date, equalTo: referenceDate, toGranularity: .month)
                let isTodayFlag = calendar.isDateInToday(date)
                days.append(CalendarDay(date: date, isCurrentMonth: isCurrentMonthFlag, isToday: isTodayFlag))
            }
        }
        return Array(days.prefix(42))
    }

    private func generateDaysInWeek(for referenceDate: Date) -> [CalendarDay] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return [] }
        var days: [CalendarDay] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: weekInterval.start) {
                let isTodayFlag = calendar.isDateInToday(date)
                let isCurrentMonthFlag = calendar.isDate(date, equalTo: referenceDate, toGranularity: .month)
                days.append(CalendarDay(date: date, isCurrentMonth: isCurrentMonthFlag, isToday: isTodayFlag))
            }
        }
        return days
    }

    private func getCompletedHabitsForDay(_ dayDate: Date) -> [Habit] {
        let startOfDay = calendar.startOfDay(for: dayDate)
        
        var dayComponent = DateComponents()
        dayComponent.day = 1
        let endOfDayOptional = calendar.date(byAdding: dayComponent, to: startOfDay)

        guard let endOfDay = endOfDayOptional else {
            print("Error: Could not calculate end of day for \(startOfDay)")
            return []
        }

        let logsForDay = allHabitLogs.filter { log in
            log.completionDate >= startOfDay && log.completionDate < endOfDay
        }
        
        let habits = Array(Set(logsForDay.compactMap { $0.habit }))
        
        return habits.sorted { h1, h2 in
            return h1.creationDate < h2.creationDate
        }
    }
    
    private func dayCellForegroundColor(for day: CalendarDay) -> Color {
        if day.isToday { return .white }
        if !day.isCurrentMonth { return .secondary }
        return .primary
    }

    private func dayCellBackgroundColor(for day: CalendarDay) -> Color {
        if day.isToday { return .red }
        return .clear
    }
    
    private func weekDayCellForegroundColor(for day: CalendarDay, isSelected: Bool) -> Color {
        if isSelected { return .white }
        if day.isToday { return .red }
        return .primary
    }

    private func weekDayCellBackgroundColor(for day: CalendarDay, isSelected: Bool) -> Color {
        if isSelected { return .red }
        return .clear
    }
    
    private func weekDayDotColor(for day: CalendarDay, isSelected: Bool) -> Color {
        if isSelected { return .white }
        if day.isToday { return .clear }
        return .red
    }
}

extension Calendar {
    var veryShortWeekdaySymbolsOrdered: [String] {
        var symbols = self.veryShortWeekdaySymbols
        let firstWeekdayIndex = self.firstWeekday - 1
        if firstWeekdayIndex > 0 && firstWeekdayIndex < symbols.count {
            symbols = Array(symbols[firstWeekdayIndex..<symbols.count] + symbols[0..<firstWeekdayIndex])
        }
        return symbols
    }
}

#Preview {
    CalendarHabitsView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}
