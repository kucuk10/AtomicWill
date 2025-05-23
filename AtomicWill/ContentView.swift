import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddHabitSheet = false
    @State private var selectedDate: Date = Date()

    @Query(sort: [SortDescriptor(\Habit.creationDate, order: .reverse)]) private var habits: [Habit]

    // The problematic @Environment(\.editMode) line has been removed.
    // On iOS, EditButton() will still correctly interact with the List's .onDelete.

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .padding(.horizontal)
                    #if os(macOS)
                    .frame(maxWidth: 250)
                    #endif

                List {
                    if habits.isEmpty {
                        ContentUnavailableView {
                            Label("No Habits Yet", systemImage: "figure.walk.arrival")
                        } description: {
                            Text("Tap the '+' button to add your first habit.")
                        }
                    } else {
                        ForEach(habits) { habit in
                            HabitRow(habit: habit, date: selectedDate)
                                #if os(macOS)
                                .contextMenu { // Context menu for macOS deletion
                                    Button("Delete", role: .destructive) {
                                        deleteHabit(habit)
                                    }
                                }
                                #endif
                        }
                        .onDelete(perform: deleteHabits) // Works with iOS EditButton & swipe.
                                                        // On macOS, may work with selection + Delete key.
                    }
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.plain) // Or .bordered on macOS
                #endif
            }
            .navigationTitle("Habits for \(selectedDate, style: .date)")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton() // This sets the \.editMode in the environment for the List on iOS
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddHabitSheet = true
                    } label: {
                        Label("Add Habit", systemImage: "plus.circle.fill")
                    }
                }
                #else // macOS
                ToolbarItemGroup(placement: .automatic) { // macOS toolbar
                    Spacer() // Optional: to push the button to the right
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
            // try? modelContext.save()
        }
    }

    // Helper for macOS context menu deletion
    private func deleteHabit(_ habit: Habit) {
        withAnimation {
            modelContext.delete(habit)
            // try? modelContext.save()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}
