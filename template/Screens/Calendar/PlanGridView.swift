import SwiftUI

struct PlanGridView: View {
    @EnvironmentObject private var environment: HausContainer

    enum Mode: String, CaseIterable, Identifiable {
        case month = "Month", week = "Week", day = "Day", agenda = "Agenda"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .month
    @State private var selectedDate = Date.now
    @State private var monthAnchor = Date.now
    @State private var events: [CalendarEvent] = []
    @State private var dayEvents: [CalendarEvent] = []
    @State private var filterType: CalendarEventType?
    @State private var showEditor = false
    @State private var editingEvent: CalendarEvent?

    var body: some View {
        ScrollView {
            VStack(spacing: GridSpacing.md) {
                Picker("View", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                filterRow

                switch mode {
                case .month: monthGrid
                case .week: weekStrip
                case .day: EmptyView()
                case .agenda: agendaList
                }

                if mode != .agenda { dayCard }
            }
            .padding(GridSpacing.md)
        }
        .background(BauhausColors.background)
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editingEvent = nil; showEditor = true } label: { Image(systemName: GridIcons.add) }
                    .accessibilityLabel("Add Event")
            }
        }
        .sheet(isPresented: $showEditor, onDismiss: reload) {
            PlanEventEditor(event: editingEvent, defaultDate: selectedDate)
        }
        .onAppear(perform: reload)
        .onChange(of: selectedDate) { _, _ in reloadDay() }
        .onChange(of: monthAnchor) { _, _ in reload() }
        .onChange(of: filterType) { _, _ in reloadDay() }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GridSpacing.xs) {
                chip("All", isOn: filterType == nil) { filterType = nil }
                ForEach(CalendarEventType.allCases) { type in
                    chip(type.displayName, isOn: filterType == type) { filterType = type }
                }
            }
        }
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(GridTypography.captionMedium)
                .padding(.horizontal, GridSpacing.sm).padding(.vertical, GridSpacing.xs)
                .background(isOn ? BauhausColors.primary : BauhausColors.surface)
                .foregroundStyle(isOn ? .black : BauhausColors.textSecondary)
                .clipShape(Capsule())
        }
    }

    private var monthGrid: some View {
        let days = monthDays()
        return VStack(spacing: GridSpacing.sm) {
            HStack {
                Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(monthAnchor.formatted(.dateTime.month(.wide).year())).font(GridTypography.title3).foregroundStyle(BauhausColors.textPrimary)
                Spacer()
                Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: GridSpacing.xs) {
                ForEach(["S","M","T","W","T","F","S"], id: \.self) { Text($0).font(.caption2).foregroundStyle(BauhausColors.textMuted) }
                ForEach(days, id: \.self) { date in
                    if let date {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let has = events.contains { DateUtils.isSameDay($0.startDate, date) }
        let isSelected = DateUtils.isSameDay(date, selectedDate)
        return Button { selectedDate = date } label: {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .black : BauhausColors.textPrimary)
                Circle().fill(has ? BauhausColors.primary : .clear).frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity).frame(height: 40)
            .background(isSelected ? BauhausColors.primary : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: SharpRadius.sm))
        }
    }

    private var weekStrip: some View {
        let (start, _) = DateUtils.weekRange(for: selectedDate)
        return HStack {
            ForEach(0..<7, id: \.self) { offset in
                let date = Calendar.current.date(byAdding: .day, value: offset, to: start) ?? start
                dayCell(date)
            }
        }
    }

    private var dayCard: some View {
        GridBlock {
            VStack(alignment: .leading, spacing: GridSpacing.sm) {
                Text(DateUtils.string(selectedDate, DateUtils.dayMonth))
                    .font(GridTypography.title3).foregroundStyle(BauhausColors.textPrimary)
                if dayEvents.isEmpty {
                    Text("No events for this day").font(GridTypography.body).foregroundStyle(BauhausColors.textMuted)
                } else {
                    ForEach(dayEvents) { event in eventRow(event) }
                }
            }
        }
    }

    private var agendaList: some View {
        VStack(spacing: GridSpacing.sm) {
            if events.isEmpty {
                BlankGridView(systemImage: GridIcons.calendar, title: "No events", message: "Create your first event to plan your training month.")
            } else {
                ForEach(events.filter { filterType == nil || $0.eventType == filterType }) { event in
                    GridBlock { eventRow(event) }
                }
            }
        }
    }

    private func eventRow(_ event: CalendarEvent) -> some View {
        Menu {
            Button("Edit") { editingEvent = event; showEditor = true }
            Menu("Set Status") {
                ForEach(CalendarEventStatus.allCases) { st in
                    Button(st.displayName) { event.status = st; try? environment.calendarRepository.saveEvent(event); reloadDay() }
                }
            }
            Button("Delete", role: .destructive) { try? environment.calendarRepository.deleteEvent(event); reload() }
        } label: {
            HStack(spacing: GridSpacing.sm) {
                Image(systemName: event.eventType.icon).foregroundStyle(BauhausColors.primary).frame(width: 24)
                VStack(alignment: .leading) {
                    Text(event.title).font(GridTypography.bodyMedium).foregroundStyle(BauhausColors.textPrimary)
                    Text(event.eventType.displayName).font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted)
                }
                Spacer()
                GridLabel(text: event.status.displayName, color: statusColor(event.status))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func statusColor(_ status: CalendarEventStatus) -> Color {
        switch status {
        case .planned: BauhausColors.info
        case .completed: BauhausColors.success
        case .skipped: BauhausColors.warning
        case .moved: BauhausColors.secondary
        case .cancelled: BauhausColors.danger
        }
    }

    private func monthDays() -> [Date?] {
        let (start, end) = DateUtils.monthRange(for: monthAnchor)
        let firstWeekday = Calendar.current.component(.weekday, from: start) - 1
        var result: [Date?] = Array(repeating: nil, count: firstWeekday)
        var d = start
        while d < end {
            result.append(d)
            d = Calendar.current.date(byAdding: .day, value: 1, to: d) ?? end
        }
        return result
    }

    private func shiftMonth(_ value: Int) {
        monthAnchor = Calendar.current.date(byAdding: .month, value: value, to: monthAnchor) ?? monthAnchor
    }

    private func reload() {
        let (start, end) = DateUtils.monthRange(for: monthAnchor)
        let wide = (Calendar.current.date(byAdding: .month, value: -1, to: start) ?? start, Calendar.current.date(byAdding: .month, value: 1, to: end) ?? end)
        events = (try? environment.calendarRepository.fetchEvents(from: wide.0, to: wide.1)) ?? []
        reloadDay()
    }

    private func reloadDay() {
        let all = (try? environment.calendarRepository.fetchEvents(for: selectedDate)) ?? []
        dayEvents = filterType == nil ? all : all.filter { $0.eventType == filterType }
    }
}
