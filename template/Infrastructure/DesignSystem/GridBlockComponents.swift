import SwiftUI

struct GridBlock<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(GridSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BauhausColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: SharpRadius.lg, ))
    }
}

struct RedActionButton: View {
    let title: String
    var systemImage: String? = nil
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            guard !isLoading else { return }
            action()
        } label: {
            HStack(spacing: GridSpacing.xs) {
                if isLoading {
                    ProgressView().tint(BauhausColors.onPrimary)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title).font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .foregroundStyle(BauhausColors.onPrimary)
            .background(BauhausColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: SharpRadius.md, ))
        }
        .disabled(isLoading)
        .accessibilityLabel(title)
    }
}

struct OutlineActionButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: GridSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title).font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .foregroundStyle(BauhausColors.textPrimary)
            .background(BauhausColors.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: SharpRadius.md, ))
        }
        .accessibilityLabel(title)
    }
}

struct GridMetric: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let color: Color
    let icon: String

    var body: some View {
        GridBlock {
            VStack(alignment: .leading, spacing: GridSpacing.sm) {
                HStack(spacing: GridSpacing.xs) {
                    Image(systemName: icon).foregroundStyle(color)
                    Text(title)
                        .font(GridTypography.captionMedium)
                        .foregroundStyle(BauhausColors.textSecondary)
                    Spacer()
                }
                Text(value)
                    .font(GridTypography.metric)
                    .foregroundStyle(BauhausColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let subtitle {
                    Text(subtitle)
                        .font(GridTypography.caption)
                        .foregroundStyle(BauhausColors.textMuted)
                }
            }
        }
    }
}

struct BlankGridView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: GridSpacing.md) {
            Spacer(minLength: GridSpacing.lg)
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(BauhausColors.textMuted)
            Text(title)
                .font(GridTypography.title3)
                .foregroundStyle(BauhausColors.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(GridTypography.body)
                .foregroundStyle(BauhausColors.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                RedActionButton(title: actionTitle, systemImage: "plus", action: action)
                    .padding(.top, GridSpacing.xs)
            }
            Spacer(minLength: GridSpacing.lg)
        }
        .padding(.horizontal, GridSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BauhausColors.background)
    }
}

struct ErrorStateView: View {
    let title: String
    let message: String
    var retryTitle: String? = nil
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: GridSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(BauhausColors.warning)
            Text(title)
                .font(GridTypography.title3)
                .foregroundStyle(BauhausColors.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(GridTypography.body)
                .foregroundStyle(BauhausColors.textSecondary)
                .multilineTextAlignment(.center)
            if let retryTitle, let retryAction {
                OutlineActionButton(title: retryTitle, systemImage: "arrow.clockwise", action: retryAction)
            }
        }
        .padding(GridSpacing.lg)
        .frame(maxWidth: .infinity)
    }
}

struct LoadingStateView: View {
    var message: String = "Loading..."
    var body: some View {
        VStack(spacing: GridSpacing.md) {
            ProgressView().tint(BauhausColors.primary)
            Text(message)
                .font(GridTypography.body)
                .foregroundStyle(BauhausColors.textSecondary)
        }
        .padding(GridSpacing.lg)
        .frame(maxWidth: .infinity)
    }
}

struct GridOfflineBar: View {
    var body: some View {
        HStack(spacing: GridSpacing.sm) {
            Image(systemName: "wifi.slash").foregroundStyle(BauhausColors.warning)
            Text("No Internet Connection. Saved data is still available.")
                .font(GridTypography.captionMedium)
                .foregroundStyle(BauhausColors.textPrimary)
            Spacer()
        }
        .padding(GridSpacing.sm)
        .background(BauhausColors.warning.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: SharpRadius.md, ))
        .accessibilityLabel("No Internet Connection. Saved data is still available.")
    }
}

struct SquareRing: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var color: Color = BauhausColors.primary

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

struct MacroLegend: View {
    let protein: Double
    let fat: Double
    let carbs: Double

    var body: some View {
        HStack(spacing: GridSpacing.md) {
            legendItem(title: "Protein", value: protein, color: BauhausColors.protein)
            legendItem(title: "Fat", value: fat, color: BauhausColors.fat)
            legendItem(title: "Carbs", value: carbs, color: BauhausColors.carbs)
        }
    }

    private func legendItem(title: String, value: Double, color: Color) -> some View {
        HStack(spacing: GridSpacing.xs) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(title) \(Int(value)) g")
                .font(GridTypography.caption)
                .foregroundStyle(BauhausColors.textSecondary)
        }
    }
}

struct GridLabel: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(GridTypography.captionMedium)
            .padding(.horizontal, GridSpacing.sm)
            .padding(.vertical, GridSpacing.xxs)
            .background(color.opacity(0.18))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(GridTypography.title3)
            .foregroundStyle(BauhausColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
