import SwiftUI

enum GridTypography {
    static let largeTitle = Font.system(size: 38, weight: .bold, design: .default)
    static let title1 = Font.system(size: 30, weight: .bold, design: .default)
    static let title2 = Font.system(size: 24, weight: .bold, design: .default)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 17, weight: .semibold, design: .default)
    static let caption = Font.system(size: 12, weight: .medium, design: .default)
    static let captionMedium = Font.system(size: 13, weight: .bold, design: .default)
    static let metric = Font.system(size: 36, weight: .heavy, design: .default)
}

enum GridSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
}

enum SharpRadius {
    static let sm: CGFloat = 0
    static let md: CGFloat = 2
    static let lg: CGFloat = 4
    static let xl: CGFloat = 6
    static let pill: CGFloat = 999
}

enum GridSize {
    static let minTouchTarget: CGFloat = 44
    static let cardMinHeight: CGFloat = 96
}

enum GridIcons {
    static let today = "square.grid.3x3.fill"
    static let workouts = "scalemass"
    static let programs = "arrow.triangle.2.circlepath"
    static let nutrition = "takeoutbag.and.cup.and.straw"
    static let library = "book"
    static let calendar = "calendar.circle"
    static let analytics = "waveform.path.ecg"
    static let settings = "slider.horizontal.3"
    static let profile = "person.fill"
    static let goals = "flag.fill"
    static let body = "ruler"
    static let water = "drop.circle"
    static let calories = "bolt.circle.fill"
    static let protein = "p.square.fill"
    static let fat = "f.square.fill"
    static let carbs = "c.square.fill"
    static let search = "magnifyingglass.circle"
    static let add = "plus.circle.fill"
    static let edit = "square.and.pencil"
    static let delete = "xmark.bin.fill"
    static let export = "arrow.up.doc.fill"
    static let importIcon = "arrow.down.doc.fill"
    static let privacy = "hand.raised.fill"
    static let offline = "antenna.radiowaves.left.and.right.slash"
    static let error = "xmark.octagon.fill"
    static let success = "checkmark.seal.fill"
}
