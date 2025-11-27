import UIKit
import AudioToolbox

/// Displays a trip progress overlay above the navigation info panel.
///
/// Shows:
/// - Skip prev/next buttons (configurable)
/// - Icon + Next waypoint name + Distance/time to it
/// - Progress bar + "Waypoint X/Y" + Total distance remaining
/// - ETA
/// - End navigation button (configurable)
///
/// The appearance can be customized via [TripProgressConfig] and [TripProgressTheme].
///
/// Layout:
/// ```
/// ┌──────────────────────────────────────────────────────────┐
/// │  [◀]   [icon] Waypoint Name                      [▶]    │
/// │              2.3 mi • ~4 min                             │
/// │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
/// │  Waypoint 3/8                      45 mi remaining      │
/// │                    ETA 2:45pm                           │
/// │                                                         │
/// │                   [End Navigation]                      │
/// └──────────────────────────────────────────────────────────┘
/// ```
public class TripProgressOverlay {

    private weak var parentViewController: UIViewController?
    private var progressCard: UIView?
    private var isVisible = false

    // Configuration
    private var config: TripProgressConfig
    private var iconProvider: IconProvider

    // Callbacks
    public var onSkipPrevious: (() -> Void)?
    public var onSkipNext: (() -> Void)?
    public var onEndNavigation: (() -> Void)?

    // UI elements for updating
    private var iconView: UIImageView?
    private var iconContainer: UIView?
    private var waypointNameLabel: UILabel?
    private var distanceTimeLabel: UILabel?
    private var progressView: UIProgressView?
    private var progressTextLabel: UILabel?
    private var totalDistanceLabel: UILabel?
    private var etaLabel: UILabel?
    private var prevButton: UIButton?
    private var nextButton: UIButton?
    private var endNavButton: UIButton?

    // Current state for button enable/disable
    private var currentWaypointIndex = 0
    private var totalWaypoints = 0

    // Bottom margin to position above the info panel
    private let bottomMargin: CGFloat = 180

    // Theme shortcut
    private var theme: TripProgressTheme { config.theme }

    public init(
        parentViewController: UIViewController,
        config: TripProgressConfig = .defaults(),
        iconProvider: IconProvider = DefaultIconProvider.shared
    ) {
        self.parentViewController = parentViewController
        self.config = config
        self.iconProvider = iconProvider
    }

    /// Update the configuration.
    public func setConfig(_ config: TripProgressConfig) {
        self.config = config
        // If visible, recreate the card with new config
        if isVisible {
            hide(animated: false)
            show()
        }
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

            self.currentWaypointIndex = data.currentWaypointIndex
            self.totalWaypoints = data.totalWaypoints

            // Update icon
            self.iconView?.image = self.iconProvider.getIcon(iconId: data.nextWaypointIconId, category: data.nextWaypointCategory)
            self.iconContainer?.backgroundColor = self.iconProvider.getCategoryColor(data.nextWaypointCategory, theme: self.theme)

            // Update waypoint name
            var displayName = data.nextWaypointName
            if displayName.count > 22 {
                displayName = String(displayName.prefix(19)) + "..."
            }
            self.waypointNameLabel?.text = displayName

            // Update distance and time
            if self.config.showDistanceToNext || self.config.showDurationToNext {
                let distStr = self.config.showDistanceToNext ? data.getFormattedDistanceToNext() : ""
                let timeStr = self.config.showDurationToNext ? data.getFormattedDurationToNext() : ""
                let separator = (self.config.showDistanceToNext && self.config.showDurationToNext) ? " • " : ""
                self.distanceTimeLabel?.text = "\(distStr)\(separator)\(timeStr)"
            }

            // Update progress bar
            if self.config.showProgressBar {
                self.progressView?.progress = data.progressFraction
            }

            // Update progress text
            if self.config.showWaypointCount {
                self.progressTextLabel?.text = data.progressString
            }

            // Update total distance
            if self.config.showTotalDistance {
                self.totalDistanceLabel?.text = "\(data.getFormattedTotalDistanceRemaining()) remaining"
            }

            // Update ETA
            if self.config.showEta {
                self.etaLabel?.text = "ETA \(data.getFormattedEta())"
            }

            // Update button states
            self.updateButtonStates()
        }
    }

    private func updateButtonStates() {
        guard config.showSkipButtons else { return }

        // Prev button: disabled if at first waypoint
        let canGoPrev = currentWaypointIndex > 0
        prevButton?.alpha = canGoPrev ? 1.0 : 0.3
        prevButton?.isEnabled = canGoPrev

        // Next button: disabled if at last waypoint
        let canGoNext = currentWaypointIndex < totalWaypoints - 1
        nextButton?.alpha = canGoNext ? 1.0 : 0.3
        nextButton?.isEnabled = canGoNext
    }

    private func playButtonSound() {
        guard config.enableAudioFeedback else { return }
        AudioServicesPlaySystemSound(1104) // Tock sound
    }

    @objc private func prevButtonTapped() {
        playButtonSound()
        onSkipPrevious?()
    }

    @objc private func nextButtonTapped() {
        playButtonSound()
        onSkipNext?()
    }

    @objc private func endNavButtonTapped() {
        playButtonSound()
        onEndNavigation?()
    }

    private func createProgressCard() -> UIView {
        // Main card container
        let card = UIView()
        card.backgroundColor = theme.backgroundColor
        card.layer.cornerRadius = theme.cornerRadius
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.12
        card.layer.shadowOffset = CGSize(width: 0, height: 3)
        card.layer.shadowRadius = 8

        // Content stack
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        // === Line 1: [◀] Icon + Waypoint Name [▶] ===
        let line1 = UIStackView()
        line1.axis = .horizontal
        line1.spacing = 12
        line1.alignment = .center

        // Prev button (only if enabled)
        if config.showSkipButtons {
            let prevBtn = createSkipButton(imageName: "chevron.left")
            prevBtn.addTarget(self, action: #selector(prevButtonTapped), for: .touchUpInside)
            prevButton = prevBtn
            line1.addArrangedSubview(prevBtn)
        }

        // Icon container
        let iconBg = UIView()
        iconBg.backgroundColor = theme.primaryColor
        iconBg.layer.cornerRadius = theme.iconSize / 2
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconBg.widthAnchor.constraint(equalToConstant: theme.iconSize),
            iconBg.heightAnchor.constraint(equalToConstant: theme.iconSize)
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
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16)
        ])
        iconView = icon

        line1.addArrangedSubview(iconBg)

        // Waypoint name (takes remaining space)
        let nameLabel = UILabel()
        nameLabel.text = "Loading..."
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = theme.textPrimaryColor
        nameLabel.textAlignment = .center
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        waypointNameLabel = nameLabel
        line1.addArrangedSubview(nameLabel)

        // Next button (only if enabled)
        if config.showSkipButtons {
            let nextBtn = createSkipButton(imageName: "chevron.right")
            nextBtn.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
            nextButton = nextBtn
            line1.addArrangedSubview(nextBtn)
        }

        contentStack.addArrangedSubview(line1)

        // === Line 2: Distance • Time ===
        if config.showDistanceToNext || config.showDurationToNext {
            let distLabel = UILabel()
            distLabel.text = "-- • --"
            distLabel.font = .systemFont(ofSize: 14)
            distLabel.textColor = theme.textSecondaryColor
            distLabel.textAlignment = .center
            distanceTimeLabel = distLabel
            contentStack.addArrangedSubview(distLabel)
        }

        // === Line 3: Progress bar ===
        if config.showProgressBar {
            let progress = UIProgressView(progressViewStyle: .default)
            progress.progress = 0
            progress.progressTintColor = theme.progressBarColor
            progress.trackTintColor = theme.progressBarBackgroundColor
            progress.layer.cornerRadius = 3
            progress.clipsToBounds = true
            progressView = progress
            contentStack.addArrangedSubview(progress)
        }

        // === Line 4: Progress text + Total distance ===
        if config.showWaypointCount || config.showTotalDistance {
            let line4 = UIStackView()
            line4.axis = .horizontal
            line4.distribution = .equalSpacing

            if config.showWaypointCount {
                let progressLabel = UILabel()
                progressLabel.text = "Waypoint 1/1"
                progressLabel.font = .systemFont(ofSize: 13)
                progressLabel.textColor = theme.textSecondaryColor
                progressTextLabel = progressLabel
                line4.addArrangedSubview(progressLabel)
            }

            if config.showTotalDistance {
                let totalLabel = UILabel()
                totalLabel.text = "-- remaining"
                totalLabel.font = .systemFont(ofSize: 13)
                totalLabel.textColor = theme.textSecondaryColor
                totalDistanceLabel = totalLabel
                line4.addArrangedSubview(totalLabel)
            }

            contentStack.addArrangedSubview(line4)
        }

        // === Line 5: ETA ===
        if config.showEta {
            let eta = UILabel()
            eta.text = "ETA --:--"
            eta.font = .systemFont(ofSize: 15, weight: .medium)
            eta.textColor = theme.primaryColor
            eta.textAlignment = .center
            etaLabel = eta
            contentStack.addArrangedSubview(eta)
        }

        // === End Navigation Button ===
        if config.showEndNavigationButton {
            let endBtn = UIButton(type: .system)
            endBtn.setTitle("End Navigation", for: .normal)
            endBtn.setTitleColor(.white, for: .normal)
            endBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            endBtn.backgroundColor = theme.endButtonColor
            endBtn.layer.cornerRadius = 8
            endBtn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
            endBtn.addTarget(self, action: #selector(endNavButtonTapped), for: .touchUpInside)
            endNavButton = endBtn
            contentStack.addArrangedSubview(endBtn)
        }

        return card
    }

    private func createSkipButton(imageName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.tintColor = theme.primaryColor
        button.backgroundColor = theme.buttonBackgroundColor
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: theme.buttonSize),
            button.heightAnchor.constraint(equalToConstant: theme.buttonSize)
        ])
        return button
    }
}
