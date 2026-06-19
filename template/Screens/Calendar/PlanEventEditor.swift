import SwiftUI

struct PlanEventEditor: View {
    @EnvironmentObject private var environment: HausContainer
    @Environment(\.dismiss) private var dismiss

    let event: CalendarEvent?
    var defaultDate: Date = .now

    @State private var title = ""
    @State private var type: CalendarEventType = .workout
    @State private var date = Date.now
    @State private var status: CalendarEventStatus = .planned
    @State private var notes = ""

    private var isEditing: Bool { event != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $type) {
                        ForEach(CalendarEventType.allCases) { Text($0.displayName).tag($0) }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Picker("Status", selection: $status) {
                        ForEach(CalendarEventStatus.allCases) { Text($0.displayName).tag($0) }
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Event" : "New Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let event {
            title = event.title; type = event.eventType; date = event.startDate; status = event.status; notes = event.notes ?? ""
        } else {
            date = defaultDate
        }
    }

    private func save() {
        let target = event ?? CalendarEvent(title: title, eventType: type, startDate: date)
        target.title = title
        target.eventType = type
        target.startDate = date
        target.status = status
        target.notes = notes.isEmpty ? nil : notes
        try? environment.calendarRepository.saveEvent(target)
        HapticsManager.success()
        dismiss()
    }
}
