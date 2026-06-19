import UIKit

enum KineticSystemChrome {
    static func apply() {
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(hex: "#FFFFFF")
        tab.shadowColor = .clear
        for layout in [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance] {
            layout.normal.iconColor = UIColor(hex: "#666666")
            layout.normal.titleTextAttributes = [.foregroundColor: UIColor(hex: "#666666")]
            layout.selected.iconColor = UIColor(hex: "#E63946")
            layout.selected.titleTextAttributes = [.foregroundColor: UIColor(hex: "#E63946")]
        }
        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tab
        tabBar.scrollEdgeAppearance = tab
        tabBar.isTranslucent = false
        tabBar.barTintColor = UIColor(hex: "#FFFFFF")
        tabBar.unselectedItemTintColor = UIColor(hex: "#666666")
        tabBar.tintColor = UIColor(hex: "#E63946")

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(hex: "#FAFAFA")
        nav.titleTextAttributes = [.foregroundColor: UIColor(hex: "#111111")]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(hex: "#111111")]
        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = nav
        navBar.scrollEdgeAppearance = nav
        navBar.compactAppearance = nav
        navBar.tintColor = UIColor(hex: "#E63946")

        UIBarButtonItem.appearance().tintColor = UIColor(hex: "#E63946")
        UITableView.appearance().backgroundColor = UIColor(hex: "#FAFAFA")
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        self.init(
            red: CGFloat((v >> 16) & 0xFF) / 255,
            green: CGFloat((v >> 8) & 0xFF) / 255,
            blue: CGFloat(v & 0xFF) / 255,
            alpha: 1
        )
    }
}
