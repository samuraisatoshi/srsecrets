import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThresholdConfigWidget extends StatelessWidget {
  final TextEditingController thresholdController;
  final TextEditingController totalSharesController;

  const ThresholdConfigWidget({
    super.key,
    required this.thresholdController,
    required this.totalSharesController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Sharing configuration section',
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Sharing Configuration',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      textField: true,
                      label: 'Threshold value input',
                      hint: 'Enter the minimum number of shares required for reconstruction',
                      child: TextFormField(
                        controller: thresholdController,
                        decoration: InputDecoration(
                          labelText: 'Threshold (k)',
                          hintText: '3',
                          prefixIcon: Semantics(
                            label: 'Key icon',
                            child: const ExcludeSemantics(
                              child: Icon(Icons.key),
                            ),
                          ),
                          helperText: 'Min shares needed',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final threshold = int.tryParse(value);
                          if (threshold == null || threshold < 2) {
                            return 'Must be ≥ 2';
                          }
                          final totalShares = int.tryParse(totalSharesController.text);
                          if (totalShares != null && threshold > totalShares) {
                            return 'Must be ≤ total shares';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Semantics(
                      textField: true,
                      label: 'Total shares input',
                      hint: 'Enter the total number of shares to create',
                      child: TextFormField(
                        controller: totalSharesController,
                        decoration: InputDecoration(
                          labelText: 'Total Shares (n)',
                          hintText: '5',
                          prefixIcon: Semantics(
                            label: 'Group icon',
                            child: const ExcludeSemantics(
                              child: Icon(Icons.group),
                            ),
                          ),
                          helperText: 'Total shares created',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final totalShares = int.tryParse(value);
                          if (totalShares == null || totalShares < 2) {
                            return 'Must be ≥ 2';
                          }
                          if (totalShares > 255) {
                            return 'Must be ≤ 255';
                          }
                          final threshold = int.tryParse(thresholdController.text);
                          if (threshold != null && totalShares < threshold) {
                            return 'Must be ≥ threshold';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Configuration explanation: Any ${thresholdController.text.isNotEmpty ? thresholdController.text : 'k'} of ${totalSharesController.text.isNotEmpty ? totalSharesController.text : 'n'} shares can reconstruct the secret',
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Semantics(
                        label: 'Information icon',
                        child: ExcludeSemantics(
                          child: Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ExcludeSemantics(
                          child: Text(
                            'Any ${thresholdController.text.isNotEmpty ? thresholdController.text : 'k'} of ${totalSharesController.text.isNotEmpty ? totalSharesController.text : 'n'} shares can reconstruct the secret',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}