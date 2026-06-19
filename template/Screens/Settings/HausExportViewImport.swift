import SwiftUI
import UniformTypeIdentifiers

struct HausExportView: View {
    @EnvironmentObject private var environment: HausContainer
    @State private var exportURL: URL?
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: GridSpacing.md) {
                Image(systemName: GridIcons.export).font(.system(size: 56)).foregroundStyle(BauhausColors.primary)
                Text("Export Your Data").font(GridTypography.title2).foregroundStyle(BauhausColors.textPrimary)
                Text("Create a local JSON backup of your workouts, nutrition, books, goals, and settings.")
                    .font(GridTypography.body).foregroundStyle(BauhausColors.textSecondary).multilineTextAlignment(.center)
                if let url = exportURL {
                    ShareLink(item: url) {
                        Label("Share Backup", systemImage: "square.and.arrow.up").font(.headline).frame(maxWidth: .infinity).frame(minHeight: 52)
                            .background(BauhausColors.primary).foregroundStyle(.black).clipShape(RoundedRectangle(cornerRadius: SharpRadius.md))
                    }
                }
                RedActionButton(title: "Export Data", systemImage: GridIcons.export) { export() }
                if let error { Text(error).font(GridTypography.caption).foregroundStyle(BauhausColors.danger) }
            }
            .padding(GridSpacing.lg)
        }
        .background(BauhausColors.background)
        .navigationTitle("Data Export")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private func export() {
        do { exportURL = try environment.exportImportService.writeExport(); HapticsManager.success() }
        catch { self.error = "Export failed." }
    }
}

struct HausImportView: View {
    @EnvironmentObject private var environment: HausContainer
    @State private var showPicker = false
    @State private var backup: BackupFile?
    @State private var preview: ImportPreview?
    @State private var mode: ImportMode = .merge
    @State private var error: String?
    @State private var done = false

    var body: some View {
        ScrollView {
            VStack(spacing: GridSpacing.md) {
                Image(systemName: GridIcons.importIcon).font(.system(size: 56)).foregroundStyle(BauhausColors.secondary)
                Text("Import Data").font(GridTypography.title2).foregroundStyle(BauhausColors.textPrimary)
                Text("Restore a JSON backup created by KineticHaus.")
                    .font(GridTypography.body).foregroundStyle(BauhausColors.textSecondary).multilineTextAlignment(.center)

                if let preview {
                    GridBlock {
                        VStack(alignment: .leading, spacing: GridSpacing.xs) {
                            SectionHeader(title: "Preview")
                            previewRow("Workouts", preview.workouts)
                            previewRow("Workout Sessions", preview.workoutSessions)
                            previewRow("Foods", preview.foods)
                            previewRow("Meals", preview.meals)
                            previewRow("Books", preview.books)
                            previewRow("Goals", preview.goals)
                            previewRow("Body Measurements", preview.bodyMeasurements)
                            previewRow("Calendar Events", preview.calendarEvents)
                        }
                    }
                    Picker("Mode", selection: $mode) {
                        Text("Merge with existing data").tag(ImportMode.merge)
                        Text("Replace all data").tag(ImportMode.replaceAll)
                    }.pickerStyle(.inline)
                    RedActionButton(title: "Confirm Import") { confirm() }
                } else {
                    RedActionButton(title: "Select JSON File", systemImage: "doc") { showPicker = true }
                }

                if done { Label("Import complete", systemImage: GridIcons.success).foregroundStyle(BauhausColors.success) }
                if let error { Text(error).font(GridTypography.caption).foregroundStyle(BauhausColors.danger) }
            }
            .padding(GridSpacing.lg)
        }
        .background(BauhausColors.background)
        .navigationTitle("Data Import")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.json]) { result in
            handle(result)
        }
    }

    private func previewRow(_ title: String, _ count: Int) -> some View {
        HStack { Text(title).foregroundStyle(BauhausColors.textSecondary); Spacer(); Text("\(count)").foregroundStyle(BauhausColors.textPrimary) }
    }

    private func handle(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let parsed = try environment.exportImportService.decode(data)
            backup = parsed
            preview = environment.exportImportService.preview(parsed)
            error = nil
        } catch let e as ExportImportError {
            error = e.errorDescription
        } catch {
            self.error = "Failed to read the backup file."
        }
    }

    private func confirm() {
        guard let backup else { return }
        do { try environment.exportImportService.performImport(backup, mode: mode); done = true; preview = nil; HapticsManager.success() }
        catch { self.error = "Import failed." }
    }
}
