//
//  AddHabitView.swift
//  AtomicWill
//
//  Created by Caner Kucuk on 5/23/25.
//
// AddHabitView.swift
// AtomicWill (or your project name)
//
// Created by [Your Name] on [Date]
//

import SwiftUI
import SwiftData

struct AddHabitView: View { // Make sure this is AddHabitView
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @State private var habitName: String = ""
    @State private var habitEmoji: String = "🎯"
    @State private var habitFrequency: HabitFrequency = .daily

    let emojis = ["🎯", "💧", "🧘", "📖", "💻", "🏋️", "🍎", "🚶", "☀️"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit Details") {
                    TextField("Habit Name (e.g., Drink Water)", text: $habitName)

                    Picker("Icon", selection: $habitEmoji) {
                        ForEach(emojis, id: \.self) { emoji in
                            Text(emoji).tag(emoji)
                        }
                    }

                    Picker("Frequency", selection: $habitFrequency) {
                        ForEach(HabitFrequency.allCases) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }
            }
            .navigationTitle("New Habit")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHabit()
                        dismiss()
                    }
                    .disabled(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                #else // macOS
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHabit()
                        dismiss()
                    }
                    .disabled(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                #endif
            }
        }
    }

    private func saveHabit() {
        let trimmedName = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let newHabit = Habit(name: trimmedName, emojiIcon: habitEmoji, targetFrequency: habitFrequency)
        modelContext.insert(newHabit)
    }
}

#Preview {
    AddHabitView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}
