import 'package:flutter/material.dart';

class ShareInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int index;
  final VoidCallback onRemove;
  final bool canRemove;
  final VoidCallback onPaste;

  const ShareInputWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.index,
    required this.onRemove,
    required this.canRemove,
    required this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Semantics(
      label: 'Share input ${index + 1}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                textField: true,
                label: 'Share ${index + 1} input field',
                hint: 'Enter or paste the share data for reconstruction',
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Share ${index + 1}',
                    hintText: 'Paste or enter share data',
                    prefixIcon: Semantics(
                      label: 'Key icon',
                      child: const ExcludeSemantics(
                        child: Icon(Icons.key),
                      ),
                    ),
                    suffixIcon: Semantics(
                      label: 'Paste from clipboard',
                      hint: 'Paste share data from device clipboard',
                      button: true,
                      child: IconButton(
                        onPressed: onPaste,
                        icon: const Icon(Icons.paste),
                        tooltip: 'Paste from clipboard',
                      ),
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Share ${index + 1} is required';
                    }
                    if (!_isValidShare(value.trim())) {
                      return 'Invalid share format';
                    }
                    return null;
                  },
                ),
              ),
            ),
            if (canRemove)
              Semantics(
                label: 'Remove share ${index + 1}',
                hint: 'Removes this share input field',
                button: true,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 48, // Ensure minimum touch target
                    minHeight: 48, // Ensure minimum touch target
                  ),
                  child: IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: theme.colorScheme.error,
                    tooltip: 'Remove share ${index + 1}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isValidShare(String share) {
    try {
      // Basic validation - should be JSON or base64
      if (share.startsWith('{') && share.endsWith('}')) {
        // Looks like JSON
        return true;
      } else if (RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(share)) {
        // Looks like base64
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}