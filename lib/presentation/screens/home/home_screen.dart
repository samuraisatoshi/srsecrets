import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/secret_provider.dart';
import '../../../domains/i18n/providers/i18n_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../secrets/secrets_list_screen.dart';
import '../secrets/create_secret_screen.dart';
import '../secrets/reconstruct_secret_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/localized_navigation_rail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  static const List<Widget> _pages = <Widget>[
    SecretsListScreen(),
    CreateSecretScreen(),
    ReconstructSecretScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final i18nProvider = context.watch<I18nProvider>();
    
    return ChangeNotifierProvider(
      create: (context) => SecretProvider(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          final isDesktop = constraints.maxWidth >= 840;
          
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.appTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  tooltip: l10n.navSettings,
                ),
                Semantics(
                  label: l10n.accessibilityOpenMenu,
                  hint: 'Access logout and account options',
                  button: true,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'logout') {
                        _showLogoutDialog(context);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Semantics(
                            label: 'Logout from application',
                            button: true,
                            child: Row(
                              children: [
                                const Icon(Icons.logout),
                                const SizedBox(width: 8),
                                Text(l10n.buttonLogout),
                              ],
                            ),
                          ),
                        ),
                      ];
                    },
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: isDesktop ? _buildDesktopLayout(context) : 
                     isTablet ? _buildTabletLayout(context) : 
                     _buildMobileLayout(context),
            ),
            bottomNavigationBar: isTablet ? null : _buildBottomNavigation(),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return _pages[_selectedIndex];
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        // Navigation rail for tablet
        Semantics(
          label: 'Navigation menu',
          child: NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.selected,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.list),
                selectedIcon: Icon(Icons.list),
                label: Text('Secrets'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: Text('Create'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.restore),
                selectedIcon: Icon(Icons.restore),
                label: Text('Reconstruct'),
              ),
            ],
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        // Main content area
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: _pages[_selectedIndex],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Extended navigation rail for desktop
        Semantics(
          label: 'Navigation menu',
          child: NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            extended: true,
            labelType: NavigationRailLabelType.none,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.list),
                selectedIcon: Icon(Icons.list),
                label: Text('Secrets'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: Text('Create'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.restore),
                selectedIcon: Icon(Icons.restore),
                label: Text('Reconstruct'),
              ),
            ],
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        // Main content area with max width constraint
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: _pages[_selectedIndex],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomNavigation() {
    return Semantics(
      label: 'Bottom navigation',
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list),
            label: 'Secrets',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.restore),
            label: 'Reconstruct',
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthProvider>().logout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}