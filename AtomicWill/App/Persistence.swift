//
//  Persistence.swift
//  AtomicWill
//

import Foundation
import SwiftData

enum Persistence {
    /// iCloud sync is turned off until the app has an iCloud container in the developer account.
    ///
    /// To turn it on:
    /// 1. Add the iCloud capability with CloudKit, using `cloudKitContainerIdentifier`.
    /// 2. Add the Background Modes capability with Remote notifications.
    /// 3. Set this flag to `true`.
    ///
    /// The models already meet CloudKit's rules: all attributes have defaults,
    /// relationships are optional, and nothing uses unique constraints.
    static let isCloudSyncEnabled = false
    static let cloudKitContainerIdentifier = "iCloud.ca.dal.kucuk.AtomicWill"

    static let schema = Schema([Habit.self, HabitCompletion.self])

    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        // Choose `.none` explicitly. The default, `.automatic`, would start syncing
        // as soon as an iCloud entitlement shows up.
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase =
            isCloudSyncEnabled && !inMemory ? .private(cloudKitContainerIdentifier) : .none

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: cloudKitDatabase
        )

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Could not create the model container: \(error)")
        }
    }
}
