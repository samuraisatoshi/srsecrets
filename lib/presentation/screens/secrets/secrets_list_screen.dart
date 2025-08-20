import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/secret_provider.dart';

class SecretsListScreen extends StatelessWidget {
  const SecretsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final secretProvider = context.watch<SecretProvider>();
    final theme = Theme.of(context);

    if (secretProvider.secrets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Secrets Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first secret using the Create tab',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Shamir\'s Secret Sharing',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Split secrets into shares where any k of n shares can reconstruct the original secret.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: secretProvider.secrets.length,
      itemBuilder: (context, index) {
        final secret = secretProvider.secrets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                _getSecretIcon(secret.type),
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              secret.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.share,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${secret.threshold} of ${secret.totalShares} shares',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(secret.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteDialog(context, secret);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              _showSecretDetails(context, secret);
            },
          ),
        );
      },
    );
  }

  IconData _getSecretIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.text_snippet;
      case 'bytes':
        return Icons.data_object;
      case 'file':
        return Icons.file_present;
      default:
        return Icons.security;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showSecretDetails(BuildContext context, SecretInfo secret) {
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(secret.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'Type', secret.type.toUpperCase()),
            _buildDetailRow(context, 'Threshold', '${secret.threshold} shares needed'),
            _buildDetailRow(context, 'Total Shares', '${secret.totalShares} shares created'),
            _buildDetailRow(context, 'Created', _formatDate(secret.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, SecretInfo secret) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Secret'),
        content: Text('Are you sure you want to delete "${secret.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await context.read<SecretProvider>().removeSecret(secret.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}