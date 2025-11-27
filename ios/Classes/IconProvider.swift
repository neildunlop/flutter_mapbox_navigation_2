import UIKit

/// Protocol for providing icons and colors based on category/iconId.
///
/// Implement this protocol to customize the icons and colors used in the
/// trip progress panel. This allows for full customization without modifying
/// the core component.
///
/// Example usage:
/// ```swift
/// class MyIconProvider: IconProvider {
///     func getIcon(iconId: String?, category: String) -> UIImage? {
///         switch (iconId ?? category).lowercased() {
///         case "custom_icon":
///             return UIImage(named: "my_custom_icon")
///         default:
///             return DefaultIconProvider.shared.getIcon(iconId: iconId, category: category)
///         }
///     }
/// }
/// ```
public protocol IconProvider {
    /// Get the icon for a waypoint.
    ///
    /// - Parameters:
    ///   - iconId: Optional specific icon ID (takes precedence over category)
    ///   - category: The waypoint category (e.g., "checkpoint", "waypoint", "poi")
    /// - Returns: UIImage for the icon, or nil if not found
    func getIcon(iconId: String?, category: String) -> UIImage?

    /// Get the color for a category.
    ///
    /// - Parameters:
    ///   - category: The waypoint category
    ///   - theme: The current theme configuration
    /// - Returns: UIColor for the category
    func getCategoryColor(_ category: String, theme: TripProgressTheme) -> UIColor
}

/// Default implementation of IconProvider.
///
/// Provides a standard set of SF Symbols icons for common waypoint types including:
/// - Checkpoints (flag)
/// - Waypoints (pin)
/// - POIs (various types like restaurants, hotels, fuel stations, etc.)
public class DefaultIconProvider: IconProvider {
    /// Shared instance for convenience.
    public static let shared = DefaultIconProvider()

    private init() {}

    /// Get the icon for a waypoint using SF Symbols.
    ///
    /// Falls back to a pin icon if the iconId/category is not recognized.
    public func getIcon(iconId: String?, category: String) -> UIImage? {
        let id = (iconId ?? category).lowercased()

        let symbolName: String
        switch id {
        case "flag", "checkpoint":
            symbolName = "flag.fill"
        case "pin", "waypoint":
            symbolName = "mappin"
        case "scenic", "viewpoint", "photo":
            symbolName = "camera.fill"
        case "petrol_station", "petrol", "gas", "fuel":
            symbolName = "fuelpump.fill"
        case "restaurant", "food", "dining":
            symbolName = "fork.knife"
        case "hotel", "accommodation", "lodging":
            symbolName = "bed.double.fill"
        case "parking", "car_park":
            symbolName = "car.fill"
        case "hospital", "medical", "clinic":
            symbolName = "cross.fill"
        case "police", "emergency":
            symbolName = "shield.fill"
        case "charging_station", "charging", "ev":
            symbolName = "bolt.fill"
        case "attraction", "landmark":
            symbolName = "flag.fill"
        case "rest_area", "rest_stop":
            symbolName = "car.fill"
        case "shop", "shopping":
            symbolName = "bag.fill"
        default:
            symbolName = "mappin"
        }

        return UIImage(systemName: symbolName)
    }

    /// Get the color for a category.
    ///
    /// Uses the theme's category colors if defined, otherwise falls back to
    /// the theme's primary color.
    public func getCategoryColor(_ category: String, theme: TripProgressTheme) -> UIColor {
        return theme.getCategoryColor(category)
    }
}
