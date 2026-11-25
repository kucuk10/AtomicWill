//
//  AtomicWillApp.swift
//  AtomicWill
//

import SwiftUI
import SwiftData

@main
struct AtomicWillApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(Persistence.shared)
    }
}
