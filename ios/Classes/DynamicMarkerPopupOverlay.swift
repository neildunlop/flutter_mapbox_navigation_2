import UIKit
import Foundation

/// Manages a floating info card for dynamic markers (e.g., team position markers).
///
/// Shows team name, speed, and last update time when a dynamic marker is tapped.
/// Uses the same theme as the trip progress panel for visual consistency.
public class DynamicMarkerPopupOverlay {

    private weak var parentViewController: UIViewController?
    private var currentMarker: DynamicMarker?
    private var cardView: UIView?
    private var isVisible = false

    // Configuration - uses same theme as trip progress for consistency
    private var config: TripProgressConfig
    private var theme: TripProgressTheme { config.theme }

    // Bottom margin to position card above the info panel
    private let bottomMargin: CGFloat = 200

    public init(parentViewController: UIViewController, config: TripProgressConfig = .defaults()) {
        self.parentViewController = parentViewController
        self.config = config
    }

    /// Update the configuration.
    public func setConfig(_ config: TripProgressConfig) {
        self.config = config
    }

    /// Initialize the overlay and set up dynamic marker tap listener.
    public func initialize() {
        DynamicMarkerManager.shared.setMarkerTapListener { [weak self] marker in
            DispatchQueue.main.async {
                self?.handleMarkerTap(marker)
            }
        }
        print("DynamicMarkerPopupOverlay: Initialized dynamic marker tap listener")
    }

    /// Clean up resources when navigation ends.
    public func cleanup() {
        DynamicMarkerManager.shared.setMarkerTapListener(nil)
        hideMarkerInfo(animated: false)
        print("DynamicMarkerPopupOverlay: Cleaned up")
    }

    private func handleMarkerTap(_ marker: DynamicMarker) {
        print("DynamicMarkerPopupOverlay: Dynamic marker tapped: \(marker.title) (\(marker.id))")

        // If same marker tapped, toggle visibility
        if currentMarker?.id == marker.id && isVisible {
            hideMarkerInfo(animated: true)
            return
        }

        // Show new marker info
        currentMarker = marker
        showMarkerInfo(marker)
    }

    private func showMarkerInfo(_ marker: DynamicMarker) {
        guard let parentVC = parentViewController else {
            print("DynamicMarkerPopupOverlay: No parent view controller")
            return
        }

        // Remove existing card if any
        cardView?.removeFromSuperview()

        // Create the marker info card
        let card = createMarkerInfoCard(marker)
        cardView = card

        // Add to parent view
        parentVC.view.addSubview(card)

        // Set up constraints
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: parentVC.view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: parentVC.view.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: parentVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -bottomMargin)
        ])

        // Animate in
        card.alpha = 0
        card.transform = CGAffineTransform(translationX: 0, y: 50)

        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            card.alpha = 1
            card.transform = .identity
        }

        isVisible = true
        print("DynamicMarkerPopupOverlay: Showing marker info for: \(marker.title)")
    }

    private func hideMarkerInfo(animated: Bool) {
        guard let card = cardView else {
            cardView = nil
            currentMarker = nil
            isVisible = false
            return
        }

        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
                card.alpha = 0
                card.transform = CGAffineTransform(translationX: 0, y: 50)
            } completion: { [weak self] _ in
                card.removeFromSuperview()
                self?.cardView = nil
                self?.currentMarker = nil
                self?.isVisible = false
            }
        } else {
            card.removeFromSuperview()
            cardView = nil
            currentMarker = nil
            isVisible = false
        }
    }

    private func createMarkerInfoCard(_ marker: DynamicMarker) -> UIView {
        // Extract metadata
        let metadata = marker.metadata ?? [:]
        let teamName = metadata["teamName"] as? String ?? marker.title
        let carNumber = metadata["carNumber"] as? Int
        let speedKmh = metadata["speedKmh"] as? Double
        let timestampStr = metadata["timestamp"] as? String
        let colorValue = metadata["colorValue"] as? Int

        // Get marker color
        let markerColor: UIColor
        if let cv = colorValue {
            markerColor = UIColor(argb: cv)
        } else if let customColor = marker.customColor, let color = UIColor(hex: customColor) {
            markerColor = color
        } else {
            markerColor = .systemBlue
        }

        // Format display name
        let displayName = carNumber != nil ? "Car \(carNumber!)" : teamName

        // Main card container
        let card = UIView()
        card.backgroundColor = theme.backgroundColor
        card.layer.cornerRadius = theme.cornerRadius
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.15
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.layer.shadowRadius = 12

        // Content stack
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            contentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        // Header row (color indicator, name, close button)
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 14
        headerStack.alignment = .center

        // Color indicator circle
        let iconContainerSize: CGFloat = 40
        let iconContainer = UIView()
        iconContainer.backgroundColor = markerColor
        iconContainer.layer.cornerRadius = iconContainerSize / 2
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: iconContainerSize),
            iconContainer.heightAnchor.constraint(equalToConstant: iconContainerSize)
        ])

        // Car icon inside the circle
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "car.fill")
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])

        headerStack.addArrangedSubview(iconContainer)

        // Title and team name stack
        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 2

        let titleLabel = UILabel()
        titleLabel.text = displayName
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textColor = theme.textPrimaryColor
        titleLabel.numberOfLines = 1
        titleStack.addArrangedSubview(titleLabel)

        // Team name (if showing car number)
        if carNumber != nil && !teamName.isEmpty {
            let teamNameLabel = UILabel()
            teamNameLabel.text = teamName
            teamNameLabel.font = .systemFont(ofSize: 13)
            teamNameLabel.textColor = markerColor
            titleStack.addArrangedSubview(teamNameLabel)
        }

        headerStack.addArrangedSubview(titleStack)

        // Spacer
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerStack.addArrangedSubview(spacer)

        // Close button
        let buttonSize = theme.buttonSize
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = theme.textSecondaryColor
        closeButton.backgroundColor = theme.buttonBackgroundColor
        closeButton.layer.cornerRadius = buttonSize / 2
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: buttonSize),
            closeButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        headerStack.addArrangedSubview(closeButton)

        contentStack.addArrangedSubview(headerStack)

        // Info row with speed and last update
        let infoStack = UIStackView()
        infoStack.axis = .horizontal
        infoStack.distribution = .fillEqually
        infoStack.spacing = 16

        // Speed column
        let speedText = speedKmh != nil ? "\(Int(speedKmh!)) km/h" : "Unknown"
        let speedColumn = createInfoColumn(
            icon: "speedometer",
            label: "Speed",
            value: speedText,
            color: theme.primaryColor
        )
        infoStack.addArrangedSubview(speedColumn)

        // Last update column
        let lastUpdateText = formatTimestamp(timestampStr)
        let updateColumn = createInfoColumn(
            icon: "clock",
            label: "Updated",
            value: lastUpdateText,
            color: theme.textSecondaryColor
        )
        infoStack.addArrangedSubview(updateColumn)

        contentStack.addArrangedSubview(infoStack)

        return card
    }

    private func createInfoColumn(icon: String, label: String, value: String, color: UIColor) -> UIStackView {
        let column = UIStackView()
        column.axis = .vertical
        column.spacing = 4
        column.alignment = .center

        // Icon
        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20)
        ])
        column.addArrangedSubview(iconView)

        // Value
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .boldSystemFont(ofSize: 15)
        valueLabel.textColor = theme.textPrimaryColor
        valueLabel.textAlignment = .center
        column.addArrangedSubview(valueLabel)

        // Label
        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 11)
        labelView.textColor = theme.textSecondaryColor
        labelView.textAlignment = .center
        column.addArrangedSubview(labelView)

        return column
    }

    private func formatTimestamp(_ timestampStr: String?) -> String {
        guard let str = timestampStr else { return "Unknown" }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: str) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: str) else {
                return "Unknown"
            }
            return formatRelativeTime(date)
        }

        return formatRelativeTime(date)
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)

        switch seconds {
        case ..<5:
            return "Just now"
        case ..<60:
            return "\(seconds)s ago"
        case ..<3600:
            return "\(seconds / 60)m ago"
        default:
            return "\(seconds / 3600)h ago"
        }
    }

    @objc private func closeButtonTapped() {
        hideMarkerInfo(animated: true)
    }
}
