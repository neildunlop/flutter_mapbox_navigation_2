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
        // Outer container with gray background for visual separation
        let outerCard = UIView()
        outerCard.backgroundColor = UIColor(red: 0.91, green: 0.91, blue: 0.91, alpha: 1.0)  // #E8E8E8
        outerCard.layer.cornerRadius = theme.cornerRadius
        outerCard.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]  // Only top corners rounded
        outerCard.layer.shadowColor = UIColor.black.cgColor
        outerCard.layer.shadowOpacity = 0.12
        outerCard.layer.shadowOffset = CGSize(width: 0, height: 3)
        outerCard.layer.shadowRadius = 8

        // Inner white container for content
        let innerCard = UIView()
        innerCard.backgroundColor = .white
        innerCard.layer.cornerRadius = 12
        innerCard.translatesAutoresizingMaskIntoConstraints = false
        outerCard.addSubview(innerCard)

        NSLayoutConstraint.activate([
            innerCard.topAnchor.constraint(equalTo: outerCard.topAnchor, constant: 10),
            innerCard.leadingAnchor.constraint(equalTo: outerCard.leadingAnchor, constant: 10),
            innerCard.trailingAnchor.constraint(equalTo: outerCard.trailingAnchor, constant: -10),
            innerCard.bottomAnchor.constraint(equalTo: outerCard.bottomAnchor, constant: -10)
        ])

        // Content stack inside the inner white card
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        innerCard.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: innerCard.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: innerCard.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: innerCard.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: innerCard.bottomAnchor, constant: -16)
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

        // Spacer between prev button and icon
        let iconSpacer = UIView()
        iconSpacer.translatesAutoresizingMaskIntoConstraints = false
        iconSpacer.widthAnchor.constraint(equalToConstant: 8).isActive = true
        line1.addArrangedSubview(iconSpacer)

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
        icon.backgroundColor = .clear  // Ensure no background on the icon
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24)
        ])
        iconView = icon

        line1.addArrangedSubview(iconBg)

        // Waypoint name (takes remaining space) - bigger text, closer to icon
        let nameLabel = UILabel()
        nameLabel.text = "Loading..."
        nameLabel.font = .systemFont(ofSize: 18, weight: .medium)
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

        return outerCard
    }

    private func createSkipButton(imageName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.tintColor = theme.primaryColor
        // Darker button background to match Android (#E0E0E0)
        button.backgroundColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: theme.buttonSize),
            button.heightAnchor.constraint(equalToConstant: theme.buttonSize)
        ])
        return button
    }
}
