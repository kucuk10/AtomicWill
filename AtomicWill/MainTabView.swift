//
//  MainTabView.swift
//  AtomicWill
//
//  Created by Caner Kucuk on 5/23/25.
//
// MainTabView.swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            AllHabitsView() // Your renamed ContentView
                .tabItem {
                    Label("Habits", systemImage: "list.bullet.clipboard.fill")
                }
                .tag(0) // Optional tag for programmatic selection

            CalendarHabitsView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar.circle.fill")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(2)
        }
        // You might want to control the accent color for selected tabs
        // .accentColor(.blue) // Or your app's primary color
        // On macOS, TabView has different styles. The default often works.
        // For macOS 13+, .tabViewStyle(.automatic) is good.
        // For macOS 14+, .tabViewStyle(.sidebarAdaptable) can offer a sidebar if appropriate.
        // For now, default should be fine.
    }
}

#Preview {
    MainTabView()
        // IMPORTANT: For previews of MainTabView to work with AllHabitsView needing data,
        // you must provide a modelContainer here as well.
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}
