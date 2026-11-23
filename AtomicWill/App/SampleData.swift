//
//  SampleData.swift
//  AtomicWill
//

import SwiftUI
import SwiftData

/// An in-memory store filled with example habits, for previews.
struct SampleData: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        let container = Persistence.makeContainer(inMemory: true)
        insertSamples(into: container.mainContext)
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }

    static func insertSamples(into context: ModelContext, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: .now)
        func daysAgo(_ value: Int) -> Date {
            calendar.date(byAdding: .day, value: -value, to: today) ?? today
        }

        let sport = Habit(name: "Sport", kind: .repeating, startDate: daysAgo(40), symbolName: "figure.run", color: .green)
        sport.period = .week
        sport.targetCount = 2

        let coffee = Habit(name: "Coffee", kind: .repeating, startDate: daysAgo(40), symbolName: "cup.and.saucer.fill", color: .brown)
        coffee.period = .week
        coffee.goalType = .limit
        coffee.targetCount = 2
        coffee.minimumCount = 1

        let read = Habit(name: "Read", kind: .repeating, startDate: daysAgo(40), symbolName: "book.fill", color: .orange)
        read.period = .day

        let water = Habit(name: "Drink water", kind: .repeating, startDate: daysAgo(40), symbolName: "drop.fill", color: .cyan)
        water.period = .day
        water.targetCount = 4

        let dentist = Habit(name: "Book dentist", kind: .oneTime, startDate: daysAgo(2), symbolName: "phone.fill", color: .purple)

        for habit in [sport, coffee, read, water, dentist] {
            context.insert(habit)
        }

        for offset in 0..<35 {
            let day = daysAgo(offset)
            if offset % 2 == 0 { read.logCompletion(on: day, calendar: calendar, in: context) }
            if offset % 3 == 0 { sport.logCompletion(on: day, calendar: calendar, in: context) }
            if offset % 4 == 1 { coffee.logCompletion(on: day, calendar: calendar, in: context) }
            for _ in 0..<(offset % 5) { water.logCompletion(on: day, calendar: calendar, in: context) }
        }
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var sampleData: Self = .modifier(SampleData())
}
