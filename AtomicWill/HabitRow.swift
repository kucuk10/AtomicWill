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
            // Option A: Continue using extracted emojiIcon
            // Text(habit.emojiIcon)
            //    .font(.title)

            // Option B: If name starts with emoji, just use name for leading visual.
            // This might look better if the emoji is integral to the name.
            // You could also combine: show emojiIcon if it's different, else part of name.
            // For now, let's stick to using the emojiIcon field as intended.
            Text(habit.emojiIcon) // This will now be the extracted first emoji or default
                .font(.title)
                .frame(width: 30, alignment: .center) // Give it some consistent space

            VStack(alignment: .leading) {
                Text(habit.name) // The full name, which might also start with an emoji
                    .font(.headline)
                Text("Frequency: \(habit.targetFrequency.rawValue)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            // ... rest of HStack
        }
        // ...
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
