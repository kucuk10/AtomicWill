//
//  CalendarModels.swift
//  AtomicWill
//
//  Created by Caner Kucuk on 5/23/25.
//
// CalendarModels.swift
import Foundation // For UUID

// Define CalendarScope globally so all views can access it
enum CalendarScope: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    var id: String { self.rawValue }
}

// Define CalendarDay globally
struct CalendarDay: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    var isCurrentMonth: Bool
    var isToday: Bool
}
