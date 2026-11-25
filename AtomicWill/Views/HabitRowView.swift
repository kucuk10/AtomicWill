//
//  HabitRowView.swift
//  AtomicWill
//

import SwiftUI
import SwiftData

/// A row in a day's list, with the controls to log or resolve the habit for that day.
struct HabitRowView: View {
    let habit: Habit
    let day: Date
    let today: Date
    var onEdit: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar

    private var isFuture: Bool {
        calendar.startOfDay(for: day) > calendar.startOfDay(for: today)
    }

    var body: some View {
        HStack(spacing: 12) {
            HabitIcon(habit: habit)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(habit.name)
                        .font(.body.weight(.medium))
                        .strikethrough(oneTimeState == .notCompleted)
                    if habit.kind == .repeating {
                        statusBadge
                    }
                }
                detail
                    .lineLimit(1)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            switch habit.kind {
            case .oneTime: taskButton
            case .repeating: logButton
            }
        }
        .contentShape(.rect)
        .swipeActions(edge: .trailing) { trailingSwipeActions }
        .contextMenu { menuActions }
    }

    // MARK: Detail text

    private var oneTimeState: OneTimeDayState? {
        habit.oneTimeState(on: day, today: today, calendar: calendar)
    }

    private var progress: HabitProgress {
        habit.progress(on: day, today: today, calendar: calendar)
    }

    @ViewBuilder
    private var detail: some View {
        switch habit.kind {
        case .oneTime:
            switch oneTimeState {
            case .carriedOver:
                Label("Carried over", systemImage: "arrow.turn.down.right")
            case .pending where calendar.startOfDay(for: habit.startDate) < calendar.startOfDay(for: day):
                Text("Scheduled \(habit.startDate, format: .dateTime.month(.abbreviated).day())")
            case .notCompleted:
                Text("Not completed")
            case .completed:
                Text("Completed")
            default:
                Text("One-time task")
            }

        case .repeating:
            Text(goalDescription)
        }
    }

    private var goalDescription: String {
        let count = progress.count
        let per = String(localized: habit.period.perTitle)
        switch habit.goalType {
        case .atLeast:
            return String(localized: "\(count) of \(habit.targetCount) \(per)")
        case .limit:
            if habit.minimumCount > 0 {
                return String(localized: "\(count) · \(habit.minimumCount)–\(habit.targetCount) \(per)")
            }
            return String(localized: "\(count) · max \(habit.targetCount) \(per)")
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch progress.status {
        case .extra:
            Badge(text: "+\(progress.extraCount) extra", color: .green)
        case .overLimit:
            Badge(text: "Over limit", color: .red)
        case .met:
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
                .accessibilityLabel("Goal met")
        case .inProgress where progress.isOnPace && habit.period != .day:
            Badge(text: "On pace", color: .orange)
        case .inProgress:
            EmptyView()
        }
    }

    // MARK: Controls

    /// Progress ring with − and + buttons for logging completions on this day.
    private var logButton: some View {
        HStack(spacing: 10) {
            if canUndoLog {
                Button("Remove Completion", systemImage: "minus") { undoLog() }
                    .labelStyle(.iconOnly)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(.fill.tertiary, in: .circle)
                    .contentShape(.circle)
                    .buttonStyle(.plain)
                    .help("Remove a completion")
                    .transition(.scale.combined(with: .opacity))
            }

            ZStack {
                ProgressRing(
                    progress: min(progress.completion, 2),
                    color: progress.status == .overLimit ? .red : habit.habitColor.color,
                    lineWidth: 4
                )
                Text(progress.count, format: .number)
                    .font(.footnote.weight(.bold).monospacedDigit())
                    .contentTransition(.numericText(value: Double(progress.count)))
            }
            .frame(width: 36, height: 36)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(goalDescription)

            Button("Log \(habit.name)", systemImage: "plus") {
                withAnimation { habit.logCompletion(on: day, calendar: calendar, in: modelContext) }
            }
            .labelStyle(.iconOnly)
            .font(.body.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(habit.habitColor.color.gradient, in: .circle)
            .contentShape(.circle)
            .buttonStyle(.plain)
            .opacity(isFuture ? 0.35 : 1)
            .disabled(isFuture)
            .help("Log a completion")
        }
        .sensoryFeedback(trigger: progress.count) { old, new in
            new > old ? .increase : .decrease
        }
    }

    private var taskButton: some View {
        Button {
            withAnimation {
                let isDone = oneTimeState == .completed
                habit.resolveTask(as: isDone ? .pending : .completed, on: day, calendar: calendar)
            }
        } label: {
            Image(systemName: taskSymbol)
                .font(.title)
                .foregroundStyle(oneTimeState == .notCompleted ? Color.secondary : habit.habitColor.color)
                .frame(width: 44, height: 44)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .disabled(isFuture || oneTimeState == .notCompleted)
        .accessibilityLabel(oneTimeState == .completed ? "Mark \(habit.name) as open" : "Complete \(habit.name)")
    }

    private var taskSymbol: String {
        switch oneTimeState {
        case .completed: "checkmark.circle.fill"
        case .notCompleted: "xmark.circle.fill"
        default: "circle"
        }
    }

    // MARK: Actions

    private var canUndoLog: Bool {
        habit.kind == .repeating && habit.completionCount(on: day, calendar: calendar) > 0
    }

    @ViewBuilder
    private var trailingSwipeActions: some View {
        switch habit.kind {
        case .repeating:
            if canUndoLog {
                Button("Undo", systemImage: "arrow.uturn.backward") { undoLog() }
                    .tint(.orange)
            }
        case .oneTime:
            if oneTimeState == .pending || oneTimeState == .carriedOver {
                Button("Not Completed", systemImage: "xmark") { markNotCompleted() }
                    .tint(.gray)
            } else if !isFuture {
                Button("Reopen", systemImage: "arrow.uturn.backward") { reopen() }
                    .tint(.orange)
            }
        }
    }

    @ViewBuilder
    private var menuActions: some View {
        switch habit.kind {
        case .repeating:
            Button("Log Completion", systemImage: "plus") {
                habit.logCompletion(on: day, calendar: calendar, in: modelContext)
            }
            .disabled(isFuture)
            Button("Undo Last Completion", systemImage: "arrow.uturn.backward") { undoLog() }
                .disabled(!canUndoLog)
        case .oneTime:
            if oneTimeState == .pending || oneTimeState == .carriedOver {
                Button("Complete", systemImage: "checkmark") {
                    habit.resolveTask(as: .completed, on: day, calendar: calendar)
                }
                .disabled(isFuture)
                Button("Mark as Not Completed", systemImage: "xmark") { markNotCompleted() }
                    .disabled(isFuture)
            } else {
                Button("Reopen", systemImage: "arrow.uturn.backward") { reopen() }
            }
        }
        Divider()
        Button("Edit", systemImage: "pencil", action: onEdit)
    }

    private func undoLog() {
        withAnimation { habit.removeCompletion(on: day, calendar: calendar, in: modelContext) }
    }

    private func markNotCompleted() {
        withAnimation { habit.resolveTask(as: .notCompleted, on: day, calendar: calendar) }
    }

    private func reopen() {
        withAnimation { habit.resolveTask(as: .pending, on: day, calendar: calendar) }
    }
}

struct HabitIcon: View {
    let habit: Habit

    var body: some View {
        Image(systemName: habit.symbolName)
            .font(.title3)
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(habit.habitColor.color.gradient, in: .rect(cornerRadius: 9))
            .accessibilityHidden(true)
    }
}

private struct Badge: View {
    let text: LocalizedStringKey
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(color)
            .background(color.opacity(0.15), in: .capsule)
            .fixedSize()
    }
}
