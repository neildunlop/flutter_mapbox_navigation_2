import UIKit

/// Displays a compact trip progress overlay above the navigation info panel.
///
/// Shows:
/// - Line 1: Icon + Next waypoint name + Distance to it
/// - Line 2: Progress bar + "Stop X/Y" + Time remaining
public class TripProgressOverlay {

    private weak var parentViewController: UIViewController?
    private var progressCard: UIView?
    private var isVisible = false

    // UI elements for updating
    private var iconView: UIImageView?
    private var iconContainer: UIView?
    private var waypointNameLabel: UILabel?
    private var distanceLabel: UILabel?
    private var progressView: UIProgressView?
    private var progressTextLabel: UILabel?
    private var timeRemainingLabel: UILabel?

    // Bottom margin to position above the info panel
    private let bottomMargin: CGFloat = 180

    public init(parentViewController: UIViewController) {
        self.parentViewController = parentViewController
    }

    /// Show the trip progress overlay.
    public func show() {
        guard !isVisible, let parentVC = parentViewController else { return }

        // Create the progress card
        let card = createProgressCard()
        progressCard = card

        // Add to parent view
        parentVC.view.addSubview(card)

        // Set up constraints
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: parentVC.view.leadingAnchor, constant: 12),
            card.trailingAnchor.constraint(equalTo: parentVC.view.trailingAnchor, constant: -12),
            card.bottomAnchor.constraint(equalTo: parentVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -bottomMargin)
        ])

        // Animate in
        card.alpha = 0
        card.transform = CGAffineTransform(translationX: 0, y: 30)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            card.alpha = 1
            card.transform = .identity
        }

        isVisible = true
        print("TripProgressOverlay: Shown")
    }

    /// Hide the trip progress overlay.
    public func hide(animated: Bool = true) {
        guard let card = progressCard else {
            progressCard = nil
            isVisible = false
            return
        }

        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
                card.alpha = 0
                card.transform = CGAffineTransform(translationX: 0, y: 30)
            } completion: { [weak self] _ in
                card.removeFromSuperview()
                self?.progressCard = nil
                self?.isVisible = false
            }
        } else {
            card.removeFromSuperview()
            progressCard = nil
            isVisible = false
        }
    }

    /// Update the overlay with new progress data.
    public func updateProgress(_ data: TripProgressData) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Update icon
            self.iconView?.image = self.getIcon(iconId: data.nextWaypointIconId, category: data.nextWaypointCategory)
            self.iconContainer?.backgroundColor = self.getCategoryColor(data.nextWaypointCategory)

            // Update waypoint name
            var displayName = data.nextWaypointName
            if displayName.count > 25 {
                displayName = String(displayName.prefix(22)) + "..."
            }
            self.waypointNameLabel?.text = "Next: \(displayName)"

            // Update distance
            self.distanceLabel?.text = data.getFormattedDistanceToNext()

            // Update progress bar
            self.progressView?.progress = data.progressFraction

            // Update progress text
            self.progressTextLabel?.text = data.progressString

            // Update time remaining
            self.timeRemainingLabel?.text = data.getFormattedDurationRemaining()
        }
    }

    private func createProgressCard() -> UIView {
        // Main card container
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.12
        card.layer.shadowOffset = CGSize(width: 0, height: 3)
        card.layer.shadowRadius = 8

        // Content stack
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            contentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])

        // === Line 1: Icon + Waypoint Name + Distance ===
        let line1 = UIStackView()
        line1.axis = .horizontal
        line1.spacing = 8
        line1.alignment = .center

        // Icon container
        let iconBg = UIView()
        iconBg.backgroundColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1)
        iconBg.layer.cornerRadius = 14
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconBg.widthAnchor.constraint(equalToConstant: 28),
            iconBg.heightAnchor.constraint(equalToConstant: 28)
        ])
        iconContainer = iconBg

        let icon = UIImageView()
        icon.image = UIImage(systemName: "flag.fill")
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 14),
            icon.heightAnchor.constraint(equalToConstant: 14)
        ])
        iconView = icon

        line1.addArrangedSubview(iconBg)

        // Waypoint name
        let nameLabel = UILabel()
        nameLabel.text = "Next: Loading..."
        nameLabel.font = .systemFont(ofSize: 14)
        nameLabel.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        waypointNameLabel = nameLabel
        line1.addArrangedSubview(nameLabel)

        // Distance
        let distLabel = UILabel()
        distLabel.text = "-- mi"
        distLabel.font = .systemFont(ofSize: 14)
        distLabel.textColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1)
        distanceLabel = distLabel
        line1.addArrangedSubview(distLabel)

        contentStack.addArrangedSubview(line1)

        // === Line 2: Progress bar + Stop X/Y + Time remaining ===
        let line2 = UIStackView()
        line2.axis = .horizontal
        line2.spacing = 10
        line2.alignment = .center

        // Progress bar
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progress = 0
        progress.progressTintColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1)
        progress.trackTintColor = UIColor(red: 0.89, green: 0.95, blue: 0.99, alpha: 1)
        progress.layer.cornerRadius = 3
        progress.clipsToBounds = true
        progress.setContentHuggingPriority(.defaultLow, for: .horizontal)
        progressView = progress
        line2.addArrangedSubview(progress)

        // Stop counter
        let stopLabel = UILabel()
        stopLabel.text = "Stop 1/1"
        stopLabel.font = .systemFont(ofSize: 12)
        stopLabel.textColor = UIColor(white: 0.4, alpha: 1)
        progressTextLabel = stopLabel
        line2.addArrangedSubview(stopLabel)

        // Separator
        let separator = UILabel()
        separator.text = "•"
        separator.font = .systemFont(ofSize: 12)
        separator.textColor = UIColor(white: 0.8, alpha: 1)
        line2.addArrangedSubview(separator)

        // Time remaining
        let timeLabel = UILabel()
        timeLabel.text = "-- min"
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = UIColor(white: 0.4, alpha: 1)
        timeRemainingLabel = timeLabel
        line2.addArrangedSubview(timeLabel)

        contentStack.addArrangedSubview(line2)

        return card
    }

    private func getCategoryColor(_ category: String) -> UIColor {
        switch category.lowercased() {
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

    private func getIcon(iconId: String?, category: String) -> UIImage? {
        let id = (iconId ?? category).lowercased()

        switch id {
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
}
