import SwiftUI

struct GridImageLoader: View {
    let urlString: String?
    var placeholderSymbol: String = "photo"
    var contentMode: ContentMode = .fill

    var body: some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            BauhausColors.elevatedSurface
                            ProgressView().tint(BauhausColors.textMuted)
                        }
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: contentMode)
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            BauhausColors.elevatedSurface
            Image(systemName: placeholderSymbol)
                .font(.title2)
                .foregroundStyle(BauhausColors.textMuted)
        }
    }
}
