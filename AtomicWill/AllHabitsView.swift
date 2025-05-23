// AllHabitsView.swift

import SwiftUI
import SwiftData

struct AllHabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddHabitSheet = false
    // No longer need selectedDate state here for the view itself,
    // but we need a constant for "today" to pass to HabitRow.
    private let today: Date = Calendar.current.startOfDay(for: Date()) // Ensures we always use the start of today

    @Query(sort: [SortDescriptor(\Habit.creationDate, order: .reverse)]) private var habits: [Habit]

    var body: some View {
        // Each tab should manage its own NavigationStack if it needs a title bar and toolbar.
        NavigationStack {
            VStack { // Removed the DatePicker from here
                List {
                    if habits.isEmpty {
                        ContentUnavailableView {
                            Label("No Habits Yet", systemImage: "figure.walk.arrival")
                        } description: {
                            Text("Tap the '+' button to add your first habit.")
                        }
                    } else {
                        ForEach(habits) { habit in
                            // Pass 'today' to HabitRow to check completion for the current day
                            HabitRow(habit: habit, date: today)
                                #if os(macOS)
                                .contextMenu { // Context menu for macOS deletion
                                    Button("Delete", role: .destructive) {
                                        deleteHabit(habit)
                                    }
                                }
                                #endif
                        }
                        .onDelete(perform: deleteHabits)
                    }
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.plain)
                #endif
            }
            .navigationTitle("Today's Habits") // Changed title to be more static
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddHabitSheet = true
                    } label: {
                        Label("Add Habit", systemImage: "plus.circle.fill")
                    }
                }
                #else // macOS
                ToolbarItemGroup(placement: .automatic) {
                    Spacer()
                    Button {
                        showingAddHabitSheet = true
                    } label: {
                        Label("Add Habit", systemImage: "plus.circle.fill")
                    }
                    .help("Add a new habit")
                }
                #endif
            }
            .sheet(isPresented: $showingAddHabitSheet) {
                AddHabitView()
                    #if os(macOS)
                    .frame(minWidth: 400, idealWidth: 450, minHeight: 300, idealHeight: 350)
                    #endif
            }
        }
    }

    private func deleteHabits(offsets: IndexSet) {
        withAnimation {
            offsets.map { habits[$0] }.forEach(modelContext.delete)
        }
    }

    private func deleteHabit(_ habit: Habit) {
        withAnimation {
            modelContext.delete(habit)
        }
    }
}

#Preview {
    AllHabitsView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}
