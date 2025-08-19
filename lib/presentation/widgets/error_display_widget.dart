import 'package:flutter/material.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onDismiss;

  const ErrorDisplayWidget({
    super.key,
    required this.errorMessage,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Error: $errorMessage',
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Semantics(
              label: 'Error icon',
              child: ExcludeSemantics(
                child: Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  errorMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
            if (onDismiss != null)
              Semantics(
                label: 'Dismiss error message',
                hint: 'Removes this error message',
                button: true,
                child: IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  tooltip: 'Dismiss error',
                ),
              ),
          ],
        ),
      ),
    );
  }
}