import SwiftUI

struct HausRootView: View {
    @AppStorage("hausConfigured") private var onboardingDone = false
    var body: some View {
        Group { onboardingDone ? AnyView(HausTabNavigator()) : AnyView(HausSetupFlow()) }
    }
}

struct HausTabNavigator: View {
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            tabContent.frame(maxWidth: .infinity, maxHeight: .infinity)
            customTabBar
        }
        .background(BauhausColors.background.ignoresSafeArea())
    }

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case 0: appNav { GridDashboardView() }
        case 1: appNav { LiftCatalogView() }
        case 2: appNav { CycleListView() }
        case 3: appNav { IntakeDayView() }
        default: appNav { CodexView() }
        }
    }

    private func appNav<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        NavigationStack {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(BauhausColors.background)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(BauhausColors.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { i in
                Button { tab = i } label: {
                    VStack(spacing: 4) {
                        Image(systemName: icons[i]).font(.system(size: 20, weight: .semibold))
                        Text(labels[i]).font(.caption2)
                    }
                    .foregroundStyle(tab == i ? BauhausColors.primary : BauhausColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(BauhausColors.surface)
    }

    private let labels = ["Grid", "Lift", "Cycle", "Intake", "Codex"]
    private let icons = [GridIcons.today, GridIcons.workouts, GridIcons.programs, GridIcons.nutrition, GridIcons.library]

}

