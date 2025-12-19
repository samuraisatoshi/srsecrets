/// Security Badges Widget
///
/// Reusable security badge components for displaying
/// security features across the application.
library;

import 'package:flutter/material.dart';

/// Data class for security badge configuration
class SecurityBadgeData {
  final IconData icon;
  final String label;
  final Color? color;

  const SecurityBadgeData({
    required this.icon,
    required this.label,
    this.color,
  });
}

/// Default security badges for the application
class DefaultSecurityBadges {
  static List<SecurityBadgeData> get defaults => const [
    SecurityBadgeData(icon: Icons.offline_bolt, label: 'Air-Gapped'),
    SecurityBadgeData(icon: Icons.lock, label: 'Encrypted'),
    SecurityBadgeData(icon: Icons.verified_user, label: 'Zero-Knowledge'),
  ];
}

/// Widget displaying a row of security badges
class SecurityBadgesRow extends StatelessWidget {
  final List<SecurityBadgeData>? badges;
  final WrapAlignment alignment;
  final double spacing;
  final double runSpacing;

  const SecurityBadgesRow({
    super.key,
    this.badges,
    this.alignment = WrapAlignment.center,
    this.spacing = 16,
    this.runSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeList = badges ?? DefaultSecurityBadges.defaults;
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
    ];

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: badgeList.asMap().entries.map((entry) {
        final index = entry.key;
        final badge = entry.value;
        final color = badge.color ?? colors[index % colors.length];
        return SecurityBadge(
          icon: badge.icon,
          label: badge.label,
          color: color,
        );
      }).toList(),
    );
  }
}

/// Individual security badge widget
class SecurityBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const SecurityBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
