//
//  HabitAppearance.swift
//  AtomicWill
//

import SwiftUI

/// The colors a habit can use. Stored by raw value, so never rename a case.
nonisolated enum HabitColor: String, CaseIterable, Identifiable {
    case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown

    var id: Self { self }

    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .mint: .mint
        case .teal: .teal
        case .cyan: .cyan
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .brown: .brown
        }
    }

    var name: LocalizedStringResource {
        switch self {
        case .red: "Red"
        case .orange: "Orange"
        case .yellow: "Yellow"
        case .green: "Green"
        case .mint: "Mint"
        case .teal: "Teal"
        case .cyan: "Cyan"
        case .blue: "Blue"
        case .indigo: "Indigo"
        case .purple: "Purple"
        case .pink: "Pink"
        case .brown: "Brown"
        }
    }
}

enum HabitSymbols {
    static let all: [String] = [
        "checkmark.circle", "star.fill", "flame.fill", "heart.fill",
        "figure.run", "figure.walk", "bicycle", "figure.pool.swim",
        "dumbbell.fill", "figure.mind.and.body", "bed.double.fill", "drop.fill",
        "leaf.fill", "fork.knife", "cup.and.saucer.fill", "pills.fill",
        "book.fill", "pencil", "brain.head.profile", "music.note",
        "paintbrush.fill", "laptopcomputer", "phone.fill", "cart.fill",
        "house.fill", "sun.max.fill", "moon.fill", "dollarsign.circle.fill",
        "gamecontroller.fill", "tv.fill", "wineglass.fill", "smoke.fill"
    ]
}

/// The groups the day's ring is broken down into, below the ring.
nonisolated enum SummaryCategory: CaseIterable {
    /// Habits with a daily goal.
    case daily
    /// Habits with a weekly or monthly goal, scored by pace.
    case goals
    /// One-time tasks scheduled on (or resolved on) the day.
    case tasks

    var title: LocalizedStringResource {
        switch self {
        case .daily: "Daily"
        case .goals: "Goals"
        case .tasks: "Tasks"
        }
    }
}

nonisolated extension Color {
    /// The day ring's color, taken from the app icon's orbit.
    static let dayRing = Color(red: 1.0, green: 0.48, blue: 0.08)
}
