//
//  AddHabitView.swift
//  AtomicWill
//
//  Created by Caner Kucuk on 5/23/25.
//
// AddHabitView.swift
// AddHabitView.swift
import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @State private var habitName: String = "" // User can type emoji here
    // @State private var habitEmoji: String = "🎯" // REMOVED
    @State private var habitFrequency: HabitFrequency = .daily
    // let emojis = ["🎯", "💧", "🧘", "📖", "💻", "🏋️", "🍎", "🚶", "☀️"] // REMOVED

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit Details") {
                    TextField("Habit Name (e.g., 💧 Drink Water)", text: $habitName) // Updated placeholder

                    // Picker("Icon", selection: $habitEmoji) { // REMOVED
                    //     ForEach(emojis, id: \.self) { emoji in
                    //         Text(emoji).tag(emoji)
                    //     }
                    // }

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

        // We need to adjust how the Habit is initialized.
        // For now, let's remove the dedicated emojiIcon parameter.
        // You'll need to decide if you want to extract the first emoji from the name
        // or if the name itself (which might contain an emoji) is sufficient.

        // Option 1: Just use the name, which might contain an emoji.
        // The `emojiIcon` property in Habit model might become redundant or be used differently.
        // For this option, you'd modify the Habit initializer.
        // Let's assume for now the `emojiIcon` property in `Habit` is meant to be extracted
        // or just defaults if no emoji is present in the name.
        // For simplicity here, we'll pass an empty string or default, assuming you'll
        // handle emoji display based on the `name` property directly in `HabitRow`.

        let firstEmoji = trimmedName.firstKnownEmoji ?? "🎯" // Extract first emoji or use default

        // Pass firstEmoji to the emojiIcon parameter.
        // Make sure your Habit model's init still takes emojiIcon
        let newHabit = Habit(name: trimmedName, emojiIcon: firstEmoji, targetFrequency: habitFrequency)
        modelContext.insert(newHabit)
    }
}

// Helper extension to find the first emoji in a string
extension String {
    var firstKnownEmoji: String? {
        self.first(where: { $0.isEmoji })?.description
    }
}

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && scalar.properties.isEmojiPresentation
    }
}


#Preview {
    AddHabitView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}
