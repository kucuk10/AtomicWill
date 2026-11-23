//
//  HabitEditorView.swift
//  AtomicWill
//

import SwiftUI
import SwiftData

/// Editable copy of a habit's settings, so Cancel leaves the model untouched.
struct HabitDraft {
    var name = ""
    var symbolName = "checkmark.circle"
    var color: HabitColor = .blue
    var notes = ""
    var kind: HabitKind = .repeating
    var startDate = Date.now
    var period: HabitPeriod = .week
    var goalType: GoalType = .atLeast
    var targetCount = 1
    var minimumCount = 0
    var weekdays: Set<Int> = []

    init(startDate: Date) {
        self.startDate = startDate
    }

    init(habit: Habit) {
        name = habit.name
        symbolName = habit.symbolName
        color = habit.habitColor
        notes = habit.notes
        kind = habit.kind
        startDate = habit.startDate
        period = habit.period
        goalType = habit.goalType
        targetCount = habit.targetCount
        minimumCount = habit.minimumCount
        weekdays = Set(habit.weekdays)
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    func apply(to habit: Habit, calendar: Calendar) {
        habit.name = trimmedName
        habit.symbolName = symbolName
        habit.habitColor = color
        habit.notes = notes
        habit.kind = kind
        habit.startDate = calendar.startOfDay(for: startDate)
        habit.period = period
        habit.goalType = goalType
        habit.targetCount = max(targetCount, 1)
        habit.minimumCount = goalType == .limit ? min(minimumCount, targetCount) : 0
        // Every weekday selected means the same as no restriction.
        habit.weekdays = period == .day && weekdays.count < 7 ? weekdays.sorted() : []
    }
}

struct HabitEditorView: View {
    private let habit: Habit?
    @State private var draft: HabitDraft
    @State private var isConfirmingDelete = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar

    init(habit: Habit) {
        self.habit = habit
        self.draft = HabitDraft(habit: habit)
    }

    init(defaultDate: Date = .now) {
        self.habit = nil
        self.draft = HabitDraft(startDate: defaultDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $draft.name)
                    SymbolPicker(selection: $draft.symbolName, color: draft.color.color)
                    HabitColorPicker(selection: $draft.color)
                }

                Section {
                    Picker("Type", selection: $draft.kind) {
                        ForEach(HabitKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                switch draft.kind {
                case .oneTime: oneTimeSection
                case .repeating: repeatingSections
                }

                Section("Notes") {
                    TextField("Notes", text: $draft.notes, axis: .vertical)
                        .lineLimit(2...6)
                }

                if habit != nil {
                    Section {
                        Button("Delete Habit", role: .destructive) { isConfirmingDelete = true }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(habit == nil ? "New Habit" : "Edit Habit")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", role: .confirm) { save() }
                        .disabled(draft.trimmedName.isEmpty)
                }
            }
            .confirmationDialog("Delete Habit?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { delete() }
            } message: {
                Text("This also deletes its history.")
            }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 560)
        #endif
    }

    // MARK: Sections

    private var oneTimeSection: some View {
        Section {
            DatePicker("Date", selection: $draft.startDate, displayedComponents: .date)
        } footer: {
            Text("If it isn't done on this day, it carries over to the next day until you complete it or mark it as not completed.")
        }
    }

    @ViewBuilder
    private var repeatingSections: some View {
        Section {
            Picker("Repeats", selection: $draft.period) {
                ForEach(HabitPeriod.allCases) { period in
                    Text(period.title).tag(period)
                }
            }
            if draft.period == .day {
                WeekdayPicker(selection: $draft.weekdays)
            }
            DatePicker("Starts", selection: $draft.startDate, displayedComponents: .date)
        } header: {
            Text("Schedule")
        } footer: {
            if draft.period == .day {
                Text("Choose the days this habit is scheduled on. Leave all days off to schedule it every day.")
            }
        }

        Section {
            Picker("Goal", selection: $draft.goalType) {
                ForEach(GoalType.allCases) { goal in
                    Text(goal.title).tag(goal)
                }
            }
            .pickerStyle(.segmented)

            switch draft.goalType {
            case .atLeast:
                Stepper(value: $draft.targetCount, in: 1...99) {
                    LabeledContent("At least", value: "\(draft.targetCount) \(String(localized: draft.period.perTitle))")
                }
            case .limit:
                Stepper(value: $draft.targetCount, in: 1...99) {
                    LabeledContent("At most", value: "\(draft.targetCount) \(String(localized: draft.period.perTitle))")
                }
                Stepper(value: $draft.minimumCount, in: 0...draft.targetCount) {
                    LabeledContent("Minimum", value: draft.minimumCount.formatted())
                }
            }
        } header: {
            Text("Goal")
        } footer: {
            switch draft.goalType {
            case .atLeast:
                Text("Completing more often than the target counts as extra.")
            case .limit:
                Text("Anything from the minimum up to the limit meets the goal. Going over the limit breaks the goal for that period.")
            }
        }
        .onChange(of: draft.targetCount) { _, newValue in
            draft.minimumCount = min(draft.minimumCount, newValue)
        }
    }

    // MARK: Actions

    private func save() {
        if let habit {
            draft.apply(to: habit, calendar: calendar)
        } else {
            let newHabit = Habit(name: draft.trimmedName, kind: draft.kind)
            draft.apply(to: newHabit, calendar: calendar)
            modelContext.insert(newHabit)
        }
        dismiss()
    }

    private func delete() {
        if let habit {
            modelContext.delete(habit)
        }
        dismiss()
    }
}

// MARK: - Pickers

private struct SymbolPicker: View {
    @Binding var selection: String
    let color: Color

    var body: some View {
        NavigationLink {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 12)], spacing: 12) {
                    ForEach(HabitSymbols.all, id: \.self) { symbol in
                        Button {
                            selection = symbol
                        } label: {
                            Image(systemName: symbol)
                                .font(.title2)
                                .frame(width: 52, height: 52)
                                .foregroundStyle(selection == symbol ? .white : color)
                                .background(
                                    selection == symbol ? AnyShapeStyle(color.gradient) : AnyShapeStyle(.fill.tertiary),
                                    in: .rect(cornerRadius: 12)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(symbol)
                        .accessibilityAddTraits(selection == symbol ? .isSelected : [])
                    }
                }
                .padding()
            }
            .navigationTitle("Icon")
        } label: {
            LabeledContent("Icon") {
                Image(systemName: selection)
                    .foregroundStyle(color)
            }
        }
    }
}

private struct HabitColorPicker: View {
    @Binding var selection: HabitColor

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(HabitColor.allCases) { habitColor in
                    Button {
                        selection = habitColor
                    } label: {
                        Circle()
                            .fill(habitColor.color.gradient)
                            .frame(width: 30, height: 30)
                            .overlay {
                                if selection == habitColor {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(habitColor.name))
                    .accessibilityAddTraits(selection == habitColor ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }
}

private struct WeekdayPicker: View {
    @Binding var selection: Set<Int>
    @Environment(\.calendar) private var calendar

    var body: some View {
        HStack(spacing: 6) {
            ForEach(calendar.orderedWeekdays, id: \.self) { weekday in
                let isOn = selection.contains(weekday)
                Button {
                    if isOn { selection.remove(weekday) } else { selection.insert(weekday) }
                } label: {
                    Text(calendar.veryShortStandaloneWeekdaySymbols[weekday - 1])
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .foregroundStyle(isOn ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                        .background(
                            isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.tertiary),
                            in: .circle
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(calendar.standaloneWeekdaySymbols[weekday - 1])
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview(traits: .sampleData) {
    HabitEditorView()
}
