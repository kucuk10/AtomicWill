//
//  AtomicWillApp.swift
//  AtomicWill
//

import SwiftUI
import SwiftData

@main
struct AtomicWillApp: App {
    private let modelContainer = Persistence.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
