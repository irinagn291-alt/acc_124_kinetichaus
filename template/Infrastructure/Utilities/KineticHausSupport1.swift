import SwiftUI

enum KineticHausSupport1 {
    static var accent: Color { BauhausColors.primary }
    static func badge(_ text: String) -> some View {
        Text(text).font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
            .background(BauhausColors.primary.opacity(0.15)).foregroundStyle(BauhausColors.primary)
            .clipShape(Capsule())
    }
}
