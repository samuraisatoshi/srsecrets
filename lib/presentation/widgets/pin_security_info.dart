/// PIN Security Info Widget
///
/// Displays PIN security requirements and guidelines.
library;

import 'package:flutter/material.dart';

/// Widget displaying PIN security requirements
class PinSecurityInfo extends StatelessWidget {
  final List<String>? requirements;

  const PinSecurityInfo({
    super.key,
    this.requirements,
  });

  static const List<String> defaultRequirements = [
    'Use 4-8 digits for your PIN',
    'Avoid sequential numbers (1234, 5678)',
    'Avoid repeated digits (1111, 0000)',
    'Choose a PIN you can remember',
    'Your PIN encrypts all operations',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reqs = requirements ?? defaultRequirements;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'PIN Security Requirements',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...reqs.map((req) => _PinRequirementRow(text: req)),
        ],
      ),
    );
  }
}

class _PinRequirementRow extends StatelessWidget {
  final String text;

  const _PinRequirementRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
