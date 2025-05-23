//
//  HabitRow.swift
//  AtomicWill
//
//  Created by Caner Kucuk on 5/23/25.
//
import SwiftUI
import SwiftData

struct HabitRow: View {
    @Bindable var habit: Habit // @Bindable allows direct two-way binding and signals mutability
    let date: Date
    @Environment(\.modelContext) private var modelContext // Essential for the toggle action

    private var isCompletedForDate: Bool {
        habit.isCompleted(for: date)
    }

    var body: some View {
        HStack {
            Text(habit.emojiIcon)
                .font(.title)
            VStack(alignment: .leading) {
                Text(habit.name)
                    .font(.headline)
                Text("Frequency: \(habit.targetFrequency.rawValue)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Button {
                withAnimation {
                    habit.toggleCompletion(for: date, modelContext: modelContext)
                    // try? modelContext.save() // Optional: if autosave needs a nudge
                }
            } label: {
                Image(systemName: isCompletedForDate ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompletedForDate ? Color.green : Color.gray) // Use Color.green etc.
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// #Preview { // Previewing HabitRow requires a sample Habit instance
//    // This is a bit more involved to set up correctly for a single row with SwiftData
//    // Focus on ContentView's preview first.
//    // If needed:
//    // struct HabitRowPreviewWrapper: View {
//    //     @State var sampleHabit = Habit(name: "Test Habit", emojiIcon: "🧪")
//    //     var body: some View {
//    //         HabitRow(habit: sampleHabit, date: Date())
//    //     }
//    // }
//    // return HabitRowPreviewWrapper()
//    //     .modelContainer(for: Habit.self, HabitLog.self, inMemory: true)
// }
