/// Feature Tile Widget
///
/// A card-style widget used on the home screen to navigate to feature demos.
/// Each tile shows the feature name, description, and category indicator.

import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/app_theme.dart';

class FeatureTile extends StatelessWidget {
  /// The feature title
  final String title;

  /// Brief description of what the feature demonstrates
  final String description;

  /// Icon to display
  final IconData icon;

  /// Route to navigate to when tapped
  final String route;

  /// Feature category (determines color accent)
  final FeatureCategory category;

  /// Optional platform note (e.g., "iOS only")
  final String? platformNote;

  /// Whether the feature is currently available
  final bool isEnabled;

  const FeatureTile({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    required this.category,
    this.platformNote,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppTheme.getCategoryColor(category);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled
            ? () => Navigator.pushNamed(context, route)
            : null,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category color bar at top
              Container(
                height: 4,
                color: categoryColor,
              ),
              Padding(
                padding: const EdgeInsets.all(UIConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon and title row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            color: categoryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (platformNote != null)
                                Text(
                                  platformNote!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.orange,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A section header for grouping feature tiles by category
class FeatureCategoryHeader extends StatelessWidget {
  final FeatureCategory category;

  const FeatureCategoryHeader({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getCategoryColor(category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        UIConstants.defaultPadding,
        UIConstants.largePadding,
        UIConstants.defaultPadding,
        UIConstants.smallPadding,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            category.label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
