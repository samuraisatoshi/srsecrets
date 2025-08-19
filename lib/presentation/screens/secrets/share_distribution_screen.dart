import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/secret_provider.dart';
import '../../widgets/share_card_widget.dart';

class ShareDistributionScreen extends StatefulWidget {
  const ShareDistributionScreen({super.key});

  @override
  State<ShareDistributionScreen> createState() => _ShareDistributionScreenState();
}

class _ShareDistributionScreenState extends State<ShareDistributionScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secretProvider = context.watch<SecretProvider>();
    final packages = secretProvider.getDistributionPackages();
    
    // Debug logging to help identify the issue
    if (packages.isEmpty && secretProvider.lastResult != null) {
      print('WARNING: lastResult exists but packages are empty');
      print('ShareSets count: ${secretProvider.lastResult?.shareSets.length}');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Distribute Shares'),
        actions: [
          IconButton(
            onPressed: () {
              _showHelpDialog(context);
            },
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: packages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Shares Available',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    secretProvider.lastResult == null
                        ? 'No secret has been generated. Please go back and create a secret.'
                        : 'Error: Shares were generated but cannot be displayed.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.share,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Share Distribution',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Distribute these ${packages.length} shares to trusted participants. Any ${secretProvider.lastResult?.threshold ?? 0} shares can reconstruct the secret.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: theme.colorScheme.onErrorContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Keep shares secure and distribute through different channels',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Shares list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: packages.length,
                    itemBuilder: (context, index) {
                      final package = packages[index];
                      return ShareCardWidget(
                        package: package,
                        index: index,
                        onCopy: () {
                          _copyShare(package.shareSet.toBase64());
                        },
                        onShare: () {
                          _sharePackage(package);
                        },
                      );
                    },
                  ),
                ),
                // Bottom actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _copyAllShares(packages);
                          },
                          icon: const Icon(Icons.copy_all),
                          label: const Text('Copy All Shares'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            secretProvider.clearResults();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _copyShare(String shareJson) {
    Clipboard.setData(ClipboardData(text: shareJson));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _sharePackage(package) {
    // In a real app, you would use share_plus package
    final shareText = '''
Secret Share ${package.participantNumber}

${package.shareSet.toJson()}

Keep this share secure. You need ${package.threshold} shares to reconstruct the secret.
''';
    
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share package copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyAllShares(List packages) {
    final allShares = packages.map((package) => {
      'participant': package.participantNumber,
      'share': package.shareSet.toJson(),
    }).toList();
    
    final shareText = allShares.map((share) => 
      'Participant ${share['participant']}:\n${share['share']}'
    ).join('\n\n---\n\n');
    
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All shares copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Distribution Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to distribute shares:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Give each share to a different trusted person'),
              Text('2. Use secure communication channels'),
              Text('3. Never send multiple shares together'),
              Text('4. Keep shares in secure storage'),
              SizedBox(height: 16),
              Text(
                'To reconstruct the secret:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Collect the required number of shares'),
              Text('2. Use the Reconstruct tab in the app'),
              Text('3. Enter each share exactly as provided'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}