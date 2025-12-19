import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domains/i18n/providers/i18n_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import 'language_settings_screen.dart';

/// Main settings screen with language selection access
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final i18nProvider = context.watch<I18nProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navSettings),
        leading: IconButton(
          icon: Icon(i18nProvider.getBackArrowIcon()),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: i18nProvider.wrapWithDirectionality(
        ListView(
          padding: i18nProvider.getDirectionalPadding(
            start: 16,
            top: 16,
            end: 16,
            bottom: 16,
          ),
          children: [
            // Language Settings Card
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.language,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.settingsLanguage),
                    subtitle: Text(
                      '${i18nProvider.currentLocale.displayName} (${i18nProvider.currentLocale.nativeName})',
                    ),
                    trailing: Icon(i18nProvider.getForwardArrowIcon()),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LanguageSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Other Settings Placeholder
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.palette,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.settingsTheme),
                    subtitle: const Text('Light / Dark mode'),
                    trailing: Icon(i18nProvider.getForwardArrowIcon()),
                    onTap: () {
                      // TODO: Implement theme settings
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Theme settings coming soon'),
                        ),
                      );
                    },
                  ),
                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      return ListTile(
                        leading: Icon(
                          Icons.pin,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Require PIN'),
                        subtitle: Text(
                          settingsProvider.isPinRequired
                              ? 'PIN required on app launch'
                              : 'No PIN required (recommended)',
                        ),
                        trailing: Switch(
                          value: settingsProvider.isPinRequired,
                          onChanged: (value) {
                            settingsProvider.setPinRequired(value);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'PIN protection enabled'
                                      : 'PIN protection disabled',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Since this app uses Shamir\'s Secret Sharing to split secrets into shares, no sensitive data is stored on this device. PIN protection is optional.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}