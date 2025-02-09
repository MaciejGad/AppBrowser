import UIKit

extension UIImage {
    /// Próbuje zwrócić ikonę aplikacji, korzystając z konfiguracji w Info.plist.
    static var appIcon: UIImage? {
        guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
              let lastIcon = iconFiles.last else { return nil }
        return UIImage(named: lastIcon)
    }
}
