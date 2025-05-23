//
//  HabitModels.swift
//  AtomicWill
//
//  Created by Caner Kucuk on 5/23/25.
//
import Foundation
import SwiftData

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var name: String
    var emojiIcon: String
    var creationDate: Date
    var targetFrequency: HabitFrequency
    var reminderTime: Date?
    var colorHex: String

    @Relationship(deleteRule: .cascade) var logs: [HabitLog]? = []

    init(id: UUID = UUID(),
         name: String = "",
         emojiIcon: String = "🎯",
         creationDate: Date = Date(),
         targetFrequency: HabitFrequency = .daily,
         reminderTime: Date? = nil,
         colorHex: String = "007AFF") {
        self.id = id
        self.name = name
        self.emojiIcon = emojiIcon
        self.creationDate = creationDate
        self.targetFrequency = targetFrequency
        self.reminderTime = reminderTime
        self.colorHex = colorHex
        // Ensure logs is initialized if you intend to append to it immediately after init elsewhere,
        // though SwiftData might handle this. It's already defaulted to [].
    }

    func isCompleted(for date: Date) -> Bool {
        guard let logs = logs else { return false } // Safely unwrap
        let calendar = Calendar.current
        return logs.contains { log in
            calendar.isDate(log.completionDate, inSameDayAs: date)
        }
    }

    func toggleCompletion(for date: Date, modelContext: ModelContext) {
        let calendar = Calendar.current

        // Ensure logs array is initialized if it was nil (though default initializer should handle it)
        if self.logs == nil {
            self.logs = []
        }

        if let existingLogIndex = self.logs!.firstIndex(where: { calendar.isDate($0.completionDate, inSameDayAs: date) }) {
            let logToRemove = self.logs![existingLogIndex]
            modelContext.delete(logToRemove) // Deleting the object from context is key
            // SwiftData should automatically update the 'self.logs' array after deletion.
            // Manually removing from self.logs![existingLogIndex] might be redundant or race with SwiftData.
        } else {
            let newLog = HabitLog(completionDate: date, habit: self) // Important: set the inverse relationship
            // modelContext.insert(newLog) // Not strictly necessary if appending to an existing managed object's relationship
            self.logs!.append(newLog) // Appending to the relationship collection is the SwiftData way
        }
        // try? modelContext.save() // Autosave is often on, but explicit save can be used if needed
    }
}

enum HabitFrequency: String, Codable, CaseIterable, Identifiable {
    case daily = "Daily"
    case specificDays = "Specific Days"
    case xTimesPerWeek = "X Times Per Week"
    var id: String { self.rawValue }
}

@Model
final class HabitLog {
    var completionDate: Date
    var habit: Habit? // Inverse relationship

    init(completionDate: Date = Date(), habit: Habit? = nil) {
        self.completionDate = completionDate
        self.habit = habit
    }
}
