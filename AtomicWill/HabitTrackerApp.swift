//
//  AtomicWillApp.swift
//  AtomicWill
//
//  Created by Caner Kucuk on 5/23/25.
//
import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            // Schemas are inferred from @Model classes
            modelContainer = try ModelContainer(for: Habit.self, HabitLog.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView() // <- CHANGE THIS
        }
        .modelContainer(modelContainer) // Make the container available to all views
    }
}
