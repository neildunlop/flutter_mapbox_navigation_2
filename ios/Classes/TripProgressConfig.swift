import UIKit

/// Configuration for the trip progress panel display.
///
/// Controls what elements are shown in the navigation info panel and how they behave.
/// This is passed from the Dart layer via method channel arguments.
public struct TripProgressConfig {
    /// Whether to show skip previous/next waypoint buttons.
    public let showSkipButtons: Bool

    /// Whether to show the overall trip progress bar.
    public let showProgressBar: Bool

    /// Whether to show the estimated time of arrival.
    public let showEta: Bool

    /// Whether to show the total distance remaining to destination.
    public let showTotalDistance: Bool

    /// Whether to show the end navigation button in the panel.
    public let showEndNavigationButton: Bool

    /// Whether to show the waypoint count (e.g., "Waypoint 3/8").
    public let showWaypointCount: Bool

    /// Whether to show distance to the next waypoint.
    public let showDistanceToNext: Bool

    /// Whether to show duration to the next waypoint.
    public let showDurationToNext: Bool

    /// Whether to play audio feedback when buttons are pressed.
    public let enableAudioFeedback: Bool

    /// Custom panel height in points. If nil, uses default height.
    public let panelHeight: CGFloat?

    /// Theme configuration for colors, typography, etc.
    public let theme: TripProgressTheme

    /// Default configuration with all features enabled.
    public init(
        showSkipButtons: Bool = true,
        showProgressBar: Bool = true,
        showEta: Bool = true,
        showTotalDistance: Bool = true,
        showEndNavigationButton: Bool = true,
        showWaypointCount: Bool = true,
        showDistanceToNext: Bool = true,
        showDurationToNext: Bool = true,
        enableAudioFeedback: Bool = true,
        panelHeight: CGFloat? = nil,
        theme: TripProgressTheme = .light()
    ) {
        self.showSkipButtons = showSkipButtons
        self.showProgressBar = showProgressBar
        self.showEta = showEta
        self.showTotalDistance = showTotalDistance
        self.showEndNavigationButton = showEndNavigationButton
        self.showWaypointCount = showWaypointCount
        self.showDistanceToNext = showDistanceToNext
        self.showDurationToNext = showDurationToNext
        self.enableAudioFeedback = enableAudioFeedback
        self.panelHeight = panelHeight
        self.theme = theme
    }

    /// Default configuration with all features enabled.
    public static func defaults() -> TripProgressConfig {
        return TripProgressConfig()
    }

    /// Minimal configuration showing only essential info.
    public static func minimal() -> TripProgressConfig {
        return TripProgressConfig(
            showSkipButtons: false,
            showProgressBar: false,
            showEta: false,
            showTotalDistance: false,
            showWaypointCount: false,
            enableAudioFeedback: false
        )
    }

    /// Creates a config from a dictionary (parsed from Dart arguments).
    public static func fromDictionary(_ dict: [String: Any]?) -> TripProgressConfig {
        guard let dict = dict else { return defaults() }

        let themeDict = dict["theme"] as? [String: Any]

        return TripProgressConfig(
            showSkipButtons: dict["showSkipButtons"] as? Bool ?? true,
            showProgressBar: dict["showProgressBar"] as? Bool ?? true,
            showEta: dict["showEta"] as? Bool ?? true,
            showTotalDistance: dict["showTotalDistance"] as? Bool ?? true,
            showEndNavigationButton: dict["showEndNavigationButton"] as? Bool ?? true,
            showWaypointCount: dict["showWaypointCount"] as? Bool ?? true,
            showDistanceToNext: dict["showDistanceToNext"] as? Bool ?? true,
            showDurationToNext: dict["showDurationToNext"] as? Bool ?? true,
            enableAudioFeedback: dict["enableAudioFeedback"] as? Bool ?? true,
            panelHeight: dict["panelHeight"] as? CGFloat,
            theme: TripProgressTheme.fromDictionary(themeDict)
        )
    }
}

/// Theme configuration for the trip progress panel.
///
/// Customize colors, typography, and dimensions to match your app's design.
public struct TripProgressTheme {
    /// Primary color used for icons, progress bars, and highlights.
    public let primaryColor: UIColor

    /// Accent color used for checkpoints and important markers.
    public let accentColor: UIColor

    /// Background color of the panel.
    public let backgroundColor: UIColor

    /// Primary text color for waypoint names and main info.
    public let textPrimaryColor: UIColor

    /// Secondary text color for distances, times, and labels.
    public let textSecondaryColor: UIColor

    /// Background color for skip/prev buttons.
    public let buttonBackgroundColor: UIColor

    /// Color for the end navigation button.
    public let endButtonColor: UIColor

    /// Color for the progress bar fill.
    public let progressBarColor: UIColor

    /// Background color for the progress bar track.
    public let progressBarBackgroundColor: UIColor

    /// Corner radius for the panel and buttons.
    public let cornerRadius: CGFloat

    /// Size of the skip/prev buttons.
    public let buttonSize: CGFloat

    /// Size of waypoint icons.
    public let iconSize: CGFloat

    /// Custom colors for different waypoint categories.
    public let categoryColors: [String: UIColor]

    /// Default category colors aligned with app's design system.
    /// Primary: #2E6578 (teal), Tertiary: #5D5D70 (muted purple-gray)
    public static let defaultCategoryColors: [String: UIColor] = [
        "checkpoint": UIColor(red: 0.36, green: 0.36, blue: 0.44, alpha: 1),    // #5D5D70 Tertiary - muted purple-gray
        "waypoint": UIColor(red: 0.18, green: 0.40, blue: 0.47, alpha: 1),      // #2E6578 Primary teal
        "poi": UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1),           // Green
        "scenic": UIColor(red: 0.55, green: 0.76, blue: 0.29, alpha: 1),        // Light Green
        "restaurant": UIColor(red: 1.0, green: 0.60, blue: 0.0, alpha: 1),      // Orange
        "food": UIColor(red: 1.0, green: 0.60, blue: 0.0, alpha: 1),            // Orange
        "hotel": UIColor(red: 0.36, green: 0.36, blue: 0.44, alpha: 1),         // Tertiary
        "accommodation": UIColor(red: 0.36, green: 0.36, blue: 0.44, alpha: 1), // Tertiary
        "petrol_station": UIColor(red: 0.38, green: 0.49, blue: 0.55, alpha: 1),// Blue Grey
        "fuel": UIColor(red: 0.38, green: 0.49, blue: 0.55, alpha: 1),          // Blue Grey
        "parking": UIColor(red: 0.47, green: 0.33, blue: 0.28, alpha: 1),       // Brown
        "hospital": UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1),      // Red
        "medical": UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1),       // Red
        "police": UIColor(red: 0.25, green: 0.32, blue: 0.71, alpha: 1),        // Indigo
        "charging_station": UIColor(red: 0.0, green: 0.74, blue: 0.83, alpha: 1)// Cyan
    ]

    public init(
        primaryColor: UIColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1),
        accentColor: UIColor = UIColor(red: 1.0, green: 0.34, blue: 0.13, alpha: 1),
        backgroundColor: UIColor = .white,
        textPrimaryColor: UIColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1),
        textSecondaryColor: UIColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1),
        buttonBackgroundColor: UIColor = UIColor(red: 0.89, green: 0.95, blue: 0.99, alpha: 1),
        endButtonColor: UIColor = UIColor(red: 0.90, green: 0.22, blue: 0.21, alpha: 1),
        progressBarColor: UIColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1),
        progressBarBackgroundColor: UIColor = UIColor(red: 0.89, green: 0.95, blue: 0.99, alpha: 1),
        cornerRadius: CGFloat = 16,
        buttonSize: CGFloat = 36,
        iconSize: CGFloat = 32,
        categoryColors: [String: UIColor] = defaultCategoryColors
    ) {
        self.primaryColor = primaryColor
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.textPrimaryColor = textPrimaryColor
        self.textSecondaryColor = textSecondaryColor
        self.buttonBackgroundColor = buttonBackgroundColor
        self.endButtonColor = endButtonColor
        self.progressBarColor = progressBarColor
        self.progressBarBackgroundColor = progressBarBackgroundColor
        self.cornerRadius = cornerRadius
        self.buttonSize = buttonSize
        self.iconSize = iconSize
        self.categoryColors = categoryColors
    }

    /// Light theme preset.
    public static func light() -> TripProgressTheme {
        return TripProgressTheme()
    }

    /// Dark theme preset.
    public static func dark() -> TripProgressTheme {
        return TripProgressTheme(
            primaryColor: UIColor(red: 0.39, green: 0.71, blue: 0.96, alpha: 1),
            accentColor: UIColor(red: 1.0, green: 0.44, blue: 0.26, alpha: 1),
            backgroundColor: UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1),
            textPrimaryColor: .white,
            textSecondaryColor: UIColor(red: 0.69, green: 0.69, blue: 0.69, alpha: 1),
            buttonBackgroundColor: UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1),
            endButtonColor: UIColor(red: 0.94, green: 0.33, blue: 0.31, alpha: 1),
            progressBarColor: UIColor(red: 0.39, green: 0.71, blue: 0.96, alpha: 1),
            progressBarBackgroundColor: UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1)
        )
    }

    /// Creates a theme from a dictionary (parsed from Dart arguments).
    public static func fromDictionary(_ dict: [String: Any]?) -> TripProgressTheme {
        guard let dict = dict else { return light() }

        let categoryColorsDict = dict["categoryColors"] as? [String: Int]
        var categoryColors = defaultCategoryColors
        if let colorsDict = categoryColorsDict {
            for (key, value) in colorsDict {
                categoryColors[key] = UIColor(argb: value)
            }
        }

        return TripProgressTheme(
            primaryColor: UIColor(argb: dict["primaryColor"] as? Int ?? 0xFF2196F3),
            accentColor: UIColor(argb: dict["accentColor"] as? Int ?? 0xFFFF5722),
            backgroundColor: UIColor(argb: dict["backgroundColor"] as? Int ?? 0xFFFFFFFF),
            textPrimaryColor: UIColor(argb: dict["textPrimaryColor"] as? Int ?? 0xFF1A1A1A),
            textSecondaryColor: UIColor(argb: dict["textSecondaryColor"] as? Int ?? 0xFF666666),
            buttonBackgroundColor: UIColor(argb: dict["buttonBackgroundColor"] as? Int ?? 0xFFE3F2FD),
            endButtonColor: UIColor(argb: dict["endButtonColor"] as? Int ?? 0xFFE53935),
            progressBarColor: UIColor(argb: dict["progressBarColor"] as? Int ?? 0xFF2196F3),
            progressBarBackgroundColor: UIColor(argb: dict["progressBarBackgroundColor"] as? Int ?? 0xFFE3F2FD),
            cornerRadius: dict["cornerRadius"] as? CGFloat ?? 16,
            buttonSize: dict["buttonSize"] as? CGFloat ?? 36,
            iconSize: dict["iconSize"] as? CGFloat ?? 32,
            categoryColors: categoryColors
        )
    }

    /// Gets the color for a specific category, falling back to primary color.
    public func getCategoryColor(_ category: String) -> UIColor {
        return categoryColors[category.lowercased()] ?? primaryColor
    }
}

// MARK: - UIColor Extension for ARGB Int

extension UIColor {
    /// Creates a UIColor from an ARGB integer (as used by Flutter Color.value).
    convenience init(argb: Int) {
        let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
        let red = CGFloat((argb >> 16) & 0xFF) / 255.0
        let green = CGFloat((argb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(argb & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
