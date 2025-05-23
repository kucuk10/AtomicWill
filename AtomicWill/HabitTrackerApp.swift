//
//  AtomicWillApp.swift
//  AtomicWill
//
//  Created by Caner Kucuk on 5/23/25.
//
import SwiftUI
import SwiftData

@main // Ensure this @main attribute is here
struct HabitTrackerApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            // Make sure BOTH Habit.self AND HabitLog.self are included
            let schema = Schema([
                Habit.self,
                HabitLog.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false) // isStoredInMemoryOnly: false for actual app data

            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            // Simpler init if you don't need a specific configuration object yet:
            // modelContainer = try ModelContainer(for: Habit.self, HabitLog.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error.localizedDescription)") // Use localizedDescription for more info
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer) // This is crucial for injecting the model context
    }
}
