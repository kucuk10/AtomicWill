//
//  RootView.swift
//  AtomicWill
//

import SwiftUI

enum AppTab: Hashable {
    case today
    case calendar
    case habits
}

struct RootView: View {
    @State private var selection: AppTab = .today
    /// The current day, refreshed at midnight and when the app comes back to the foreground.
    @State private var today = Date.now
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selection) {
            Tab("Today", systemImage: "checklist", value: AppTab.today) {
                TodayView(today: today)
            }
            Tab("Calendar", systemImage: "calendar", value: AppTab.calendar) {
                CalendarScreen(today: today)
            }
            Tab("Habits", systemImage: "square.stack.3d.up", value: AppTab.habits) {
                HabitsListView(today: today)
            }
        }
        // A tab bar on iPhone, and a sidebar on iPad and Mac.
        .tabViewStyle(.sidebarAdaptable)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { today = .now }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                today = .now
            }
        }
    }
}

#Preview(traits: .sampleData) {
    RootView()
}
