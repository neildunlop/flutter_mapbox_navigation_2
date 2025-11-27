import UIKit
import Foundation

/// Manages a floating marker info card that appears above the navigation UI.
///
/// This class creates a card view overlay that floats above the Mapbox navigation view,
/// showing details when a marker is tapped.
public class MarkerPopupOverlay {

    private weak var parentViewController: UIViewController?
    private var currentMarker: StaticMarker?
    private var cardView: UIView?
    private var isVisible = false

    // Bottom margin to position card above the info panel
    private let bottomMargin: CGFloat = 200

    public init(parentViewController: UIViewController) {
        self.parentViewController = parentViewController
    }

    /// Initialize the overlay and set up marker tap listener.
    public func initialize() {
        StaticMarkerManager.shared.setMarkerTapListener { [weak self] marker in
            DispatchQueue.main.async {
                self?.handleMarkerTap(marker)
            }
        }
        print("MarkerPopupOverlay: Initialized marker tap listener")
    }

    /// Clean up resources when navigation ends.
    public func cleanup() {
        StaticMarkerManager.shared.setMarkerTapListener(nil)
        hideMarkerInfo(animated: false)
        print("MarkerPopupOverlay: Cleaned up")
    }

    private func handleMarkerTap(_ marker: StaticMarker) {
        print("MarkerPopupOverlay: Marker tapped: \(marker.title)")

        // If same marker tapped, toggle visibility
        if currentMarker?.id == marker.id && isVisible {
            hideMarkerInfo(animated: true)
            return
        }

        // Show new marker info
        currentMarker = marker
        showMarkerInfo(marker)
    }

    private func showMarkerInfo(_ marker: StaticMarker) {
        guard let parentVC = parentViewController else {
            print("MarkerPopupOverlay: No parent view controller")
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
        print("MarkerPopupOverlay: Showing marker info for: \(marker.title)")
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

    private func createMarkerInfoCard(_ marker: StaticMarker) -> UIView {
        // Main card container
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.15
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.layer.shadowRadius = 12

        // Content stack
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            contentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        // Header row (icon, title/category, close button)
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 14
        headerStack.alignment = .center

        // Icon circle
        let iconContainer = UIView()
        iconContainer.backgroundColor = getMarkerColor(marker)
        iconContainer.layer.cornerRadius = 22
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44)
        ])

        let iconImageView = UIImageView()
        iconImageView.image = getMarkerIcon(marker)
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22)
        ])

        headerStack.addArrangedSubview(iconContainer)

        // Title and category stack
        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 2

        let titleLabel = UILabel()
        titleLabel.text = marker.title
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        titleLabel.numberOfLines = 2
        titleStack.addArrangedSubview(titleLabel)

        if !marker.category.isEmpty {
            let categoryLabel = UILabel()
            categoryLabel.text = formatCategory(marker.category)
            categoryLabel.font = .systemFont(ofSize: 13)
            categoryLabel.textColor = getMarkerColor(marker)
            titleStack.addArrangedSubview(categoryLabel)
        }

        headerStack.addArrangedSubview(titleStack)

        // Spacer
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerStack.addArrangedSubview(spacer)

        // Close button
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = UIColor(white: 0.4, alpha: 1)
        closeButton.backgroundColor = UIColor(white: 0.96, alpha: 1)
        closeButton.layer.cornerRadius = 18
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        headerStack.addArrangedSubview(closeButton)

        contentStack.addArrangedSubview(headerStack)

        // Description if available
        let description = marker.description ?? marker.metadata?["description"] as? String
        if let desc = description, !desc.isEmpty {
            let descLabel = UILabel()
            descLabel.text = desc
            descLabel.font = .systemFont(ofSize: 14)
            descLabel.textColor = UIColor(white: 0.33, alpha: 1)
            descLabel.numberOfLines = 3
            contentStack.addArrangedSubview(descLabel)
        }

        // ETA if available
        if let eta = marker.metadata?["eta"] as? String, !eta.isEmpty, eta != "null" {
            let etaStack = UIStackView()
            etaStack.axis = .horizontal
            etaStack.spacing = 6
            etaStack.alignment = .center

            let clockImage = UIImageView()
            clockImage.image = UIImage(systemName: "clock")
            clockImage.tintColor = UIColor(white: 0.53, alpha: 1)
            clockImage.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                clockImage.widthAnchor.constraint(equalToConstant: 16),
                clockImage.heightAnchor.constraint(equalToConstant: 16)
            ])
            etaStack.addArrangedSubview(clockImage)

            let etaLabel = UILabel()
            etaLabel.text = "ETA: \(eta)"
            etaLabel.font = .systemFont(ofSize: 13)
            etaLabel.textColor = UIColor(white: 0.4, alpha: 1)
            etaStack.addArrangedSubview(etaLabel)

            // Spacer to push content left
            let etaSpacer = UIView()
            etaSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            etaStack.addArrangedSubview(etaSpacer)

            contentStack.addArrangedSubview(etaStack)
        }

        return card
    }

    @objc private func closeButtonTapped() {
        hideMarkerInfo(animated: true)
    }

    private func getMarkerColor(_ marker: StaticMarker) -> UIColor {
        if let customColor = marker.customColor {
            return customColor
        }

        switch marker.category.lowercased() {
        case "checkpoint":
            return UIColor(red: 1.0, green: 0.34, blue: 0.13, alpha: 1) // Deep Orange
        case "waypoint":
            return UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1) // Blue
        case "poi":
            return UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1) // Green
        case "scenic":
            return UIColor(red: 0.55, green: 0.76, blue: 0.29, alpha: 1) // Light Green
        case "restaurant", "food":
            return UIColor(red: 1.0, green: 0.60, blue: 0.0, alpha: 1) // Orange
        case "hotel", "accommodation":
            return UIColor(red: 0.61, green: 0.15, blue: 0.69, alpha: 1) // Purple
        case "petrol_station", "fuel":
            return UIColor(red: 0.38, green: 0.49, blue: 0.55, alpha: 1) // Blue Grey
        default:
            return UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1) // Default blue
        }
    }

    private func getMarkerIcon(_ marker: StaticMarker) -> UIImage? {
        let iconId = marker.iconId?.lowercased() ?? marker.category.lowercased()

        // Try to use SF Symbols for icons
        switch iconId {
        case "flag", "checkpoint":
            return UIImage(systemName: "flag.fill")
        case "pin", "waypoint":
            return UIImage(systemName: "mappin")
        case "scenic":
            return UIImage(systemName: "camera.fill")
        case "petrol_station", "petrol", "gas", "fuel":
            return UIImage(systemName: "fuelpump.fill")
        case "restaurant", "food":
            return UIImage(systemName: "fork.knife")
        case "hotel", "accommodation":
            return UIImage(systemName: "bed.double.fill")
        case "parking":
            return UIImage(systemName: "car.fill")
        case "hospital", "medical":
            return UIImage(systemName: "cross.fill")
        case "police":
            return UIImage(systemName: "shield.fill")
        case "charging_station", "charging":
            return UIImage(systemName: "bolt.fill")
        default:
            return UIImage(systemName: "mappin")
        }
    }

    private func formatCategory(_ category: String) -> String {
        return category
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}
