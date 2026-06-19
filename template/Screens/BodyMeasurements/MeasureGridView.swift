import SwiftUI
import Charts

struct MeasureGridView: View {
    @EnvironmentObject private var environment: HausContainer
    @State private var measurements: [BodyMeasurement] = []
    @State private var showEditor = false
    @State private var editing: BodyMeasurement?

    var body: some View {
        Group {
            if measurements.isEmpty {
                BlankGridView(systemImage: GridIcons.body, title: "No measurements yet", message: "Add your first body measurement to track progress.", actionTitle: "Add Measurement") { editing = nil; showEditor = true }
            } else {
                ScrollView {
                    VStack(spacing: GridSpacing.md) {
                        weightChart
                        ForEach(measurements) { m in
                            Button { editing = m; showEditor = true } label: { row(m) }
                        }
                    }
                    .padding(GridSpacing.md)
                }
            }
        }
        .background(BauhausColors.background)
        .navigationTitle("Body Measurements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { editing = nil; showEditor = true } label: { Image(systemName: GridIcons.add) }.accessibilityLabel("Add Measurement") } }
        .sheet(isPresented: $showEditor, onDismiss: reload) { MeasurementEditorView(measurement: editing) }
        .onAppear(perform: reload)
    }

    private var weightChart: some View {
        let points = measurements.compactMap { m in m.weightKg.map { (m.date, $0) } }.sorted { $0.0 < $1.0 }
        return GridBlock {
            VStack(alignment: .leading, spacing: GridSpacing.sm) {
                SectionHeader(title: "Weight Trend")
                if points.count < 2 {
                    Text("Add more measurements to see a trend.").font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted)
                } else {
                    Chart(points, id: \.0) { point in
                        LineMark(x: .value("Date", point.0), y: .value("Weight", point.1))
                            .foregroundStyle(BauhausColors.primary)
                        PointMark(x: .value("Date", point.0), y: .value("Weight", point.1))
                            .foregroundStyle(BauhausColors.primary)
                    }
                    .frame(height: 180)
                }
            }
        }
    }

    private func row(_ m: BodyMeasurement) -> some View {
        GridBlock {
            HStack {
                VStack(alignment: .leading) {
                    Text(DateUtils.string(m.date)).foregroundStyle(BauhausColors.textPrimary)
                    HStack(spacing: GridSpacing.sm) {
                        if let w = m.weightKg { Text("\(NumberFormatterUtils.decimal(w)) kg") }
                        if let bf = m.bodyFatPercent { Text("\(NumberFormatterUtils.decimal(bf))% bf") }
                        if let waist = m.waistCm { Text("waist \(NumberFormatterUtils.decimal(waist))") }
                    }.font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(BauhausColors.textMuted)
            }
        }
    }

    private func reload() { measurements = (try? environment.bodyRepository.fetchMeasurements()) ?? [] }
}

struct MeasurementEditorView: View {
    @EnvironmentObject private var environment: HausContainer
    @Environment(\.dismiss) private var dismiss
    let measurement: BodyMeasurement?

    @State private var date = Date.now
    @State private var weight = ""
    @State private var bodyFat = ""
    @State private var muscle = ""
    @State private var waist = ""
    @State private var chest = ""
    @State private var hips = ""
    @State private var arm = ""
    @State private var thigh = ""
    @State private var neck = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Section("Composition") {
                    field("Weight (kg)", $weight); field("Body Fat (%)", $bodyFat); field("Muscle Mass (kg)", $muscle)
                }
                Section("Measurements (cm)") {
                    field("Waist", $waist); field("Chest", $chest); field("Hips", $hips); field("Arm", $arm); field("Thigh", $thigh); field("Neck", $neck)
                }
                Section("Note") { TextField("Note", text: $note, axis: .vertical).lineLimit(2...4) }
                if measurement != nil {
                    Button(role: .destructive) { try? environment.bodyRepository.deleteMeasurement(measurement!); dismiss() } label: { Text("Delete Measurement") }
                }
            }
            .navigationTitle(measurement == nil ? "Add Measurement" : "Edit Measurement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private func field(_ title: String, _ binding: Binding<String>) -> some View {
        HStack { Text(title); Spacer(); TextField("—", text: binding).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 100) }
    }

    private func load() {
        guard let m = measurement else { return }
        date = m.date; weight = m.weightKg.map { String($0) } ?? ""; bodyFat = m.bodyFatPercent.map { String($0) } ?? ""
        muscle = m.muscleMassKg.map { String($0) } ?? ""; waist = m.waistCm.map { String($0) } ?? ""
        chest = m.chestCm.map { String($0) } ?? ""; hips = m.hipsCm.map { String($0) } ?? ""
        arm = m.armCm.map { String($0) } ?? ""; thigh = m.thighCm.map { String($0) } ?? ""; neck = m.neckCm.map { String($0) } ?? ""
        note = m.note ?? ""
    }

    private func save() {
        let target = measurement ?? BodyMeasurement(date: date)
        target.date = date
        target.weightKg = Double(weight); target.bodyFatPercent = Double(bodyFat); target.muscleMassKg = Double(muscle)
        target.waistCm = Double(waist); target.chestCm = Double(chest); target.hipsCm = Double(hips)
        target.armCm = Double(arm); target.thighCm = Double(thigh); target.neckCm = Double(neck)
        target.note = note.isEmpty ? nil : note
        try? environment.bodyRepository.saveMeasurement(target)
        HapticsManager.success(); dismiss()
    }
}
