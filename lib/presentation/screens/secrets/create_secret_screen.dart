import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/secret_provider.dart';
import '../../widgets/secret_form_header.dart';
import '../../widgets/threshold_config_widget.dart';
import '../../widgets/error_display_widget.dart';
import 'share_distribution_screen.dart';

class CreateSecretScreen extends StatefulWidget {
  const CreateSecretScreen({super.key});

  @override
  State<CreateSecretScreen> createState() => _CreateSecretScreenState();
}

class _CreateSecretScreenState extends State<CreateSecretScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _secretController = TextEditingController();
  final _thresholdController = TextEditingController(text: '3');
  final _totalSharesController = TextEditingController(text: '5');

  @override
  void dispose() {
    _nameController.dispose();
    _secretController.dispose();
    _thresholdController.dispose();
    _totalSharesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secretProvider = context.watch<SecretProvider>();
    final screenSize = MediaQuery.sizeOf(context);
    final isTablet = screenSize.width >= 600;
    final isLandscape = screenSize.width > screenSize.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
          child: Form(
            key: _formKey,
            child: _buildResponsiveLayout(
              context,
              secretProvider,
              constraints,
              isTablet,
              isLandscape,
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveLayout(
    BuildContext context,
    SecretProvider secretProvider,
    BoxConstraints constraints,
    bool isTablet,
    bool isLandscape,
  ) {
    final contentWidth = isTablet 
        ? (constraints.maxWidth > 800 ? 800.0 : constraints.maxWidth)
        : constraints.maxWidth;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SecretFormHeader(
              title: 'Create Secret Shares',
              subtitle: 'Split your secret into multiple shares using Shamir\'s Secret Sharing algorithm',
              icon: Icons.add_circle_outline,
            ),
            SizedBox(height: isTablet ? 24 : 16),
            
            if (isTablet && isLandscape)
              _buildTabletLandscapeLayout(
                secretProvider,
                isTablet,
              )
            else
              _buildVerticalLayout(
                secretProvider,
                isTablet,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(
    SecretProvider secretProvider,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Secret name
        Semantics(
          textField: true,
          label: 'Secret name input',
          hint: 'Enter a descriptive name for your secret',
          child: TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Secret Name',
              hintText: 'Enter a name for your secret',
              prefixIcon: Semantics(
                label: 'Name icon',
                child: const ExcludeSemantics(child: Icon(Icons.label)),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a name for your secret';
              }
              return null;
            },
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        
        // Secret content
        Semantics(
          textField: true,
          label: 'Secret content input',
          hint: 'Enter the secret text to be shared',
          child: TextFormField(
            controller: _secretController,
            decoration: InputDecoration(
              labelText: 'Secret',
              hintText: 'Enter your secret text',
              prefixIcon: Semantics(
                label: 'Security icon',
                child: const ExcludeSemantics(child: Icon(Icons.security)),
              ),
            ),
            maxLines: isTablet ? 6 : 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your secret';
              }
              if (value.trim().length < 4) {
                return 'Secret must be at least 4 characters long';
              }
              return null;
            },
          ),
        ),
        SizedBox(height: isTablet ? 32 : 24),
        
        // Threshold configuration
        ThresholdConfigWidget(
          thresholdController: _thresholdController,
          totalSharesController: _totalSharesController,
        ),
        SizedBox(height: isTablet ? 32 : 24),
        
        // Error message
        if (secretProvider.errorMessage != null)
          ErrorDisplayWidget(
            errorMessage: secretProvider.errorMessage!,
            onDismiss: secretProvider.clearError,
          ),
        
        // Create button
        SizedBox(
          width: double.infinity,
          height: isTablet ? 56 : 48,
          child: Semantics(
            label: 'Create secret shares',
            hint: 'Creates shares from your secret using the specified threshold',
            button: true,
            child: ElevatedButton(
              onPressed: secretProvider.isLoading ? null : _createSecret,
              child: secretProvider.isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'Creating secret shares',
                      ),
                    )
                  : Text(
                      'Create Secret Shares',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLandscapeLayout(
    SecretProvider secretProvider,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Top row with name and secret fields
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Semantics(
                textField: true,
                label: 'Secret name input',
                hint: 'Enter a descriptive name for your secret',
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Secret Name',
                    hintText: 'Enter a name for your secret',
                    prefixIcon: Semantics(
                      label: 'Name icon',
                      child: const ExcludeSemantics(child: Icon(Icons.label)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name for your secret';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Semantics(
                textField: true,
                label: 'Secret content input',
                hint: 'Enter the secret text to be shared',
                child: TextFormField(
                  controller: _secretController,
                  decoration: InputDecoration(
                    labelText: 'Secret',
                    hintText: 'Enter your secret text',
                    prefixIcon: Semantics(
                      label: 'Security icon',
                      child: const ExcludeSemantics(child: Icon(Icons.security)),
                    ),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your secret';
                    }
                    if (value.trim().length < 4) {
                      return 'Secret must be at least 4 characters long';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        // Threshold configuration
        ThresholdConfigWidget(
          thresholdController: _thresholdController,
          totalSharesController: _totalSharesController,
        ),
        const SizedBox(height: 32),
        
        // Error and button row
        Column(
          children: [
            if (secretProvider.errorMessage != null)
              ErrorDisplayWidget(
                errorMessage: secretProvider.errorMessage!,
                onDismiss: secretProvider.clearError,
              ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Semantics(
                label: 'Create secret shares',
                hint: 'Creates shares from your secret using the specified threshold',
                button: true,
                child: ElevatedButton(
                  onPressed: secretProvider.isLoading ? null : _createSecret,
                  child: secretProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: 'Creating secret shares',
                          ),
                        )
                      : const Text(
                          'Create Secret Shares',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _createSecret() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final secretProvider = context.read<SecretProvider>();
    
    try {
      final success = await secretProvider.createSecret(
        secretName: _nameController.text.trim(),
        secret: _secretController.text.trim(),
        threshold: int.parse(_thresholdController.text),
        totalShares: int.parse(_totalSharesController.text),
      );

      if (!mounted) return;
      
      if (success) {
        // Validate that the secret is ready
        if (!secretProvider.isSecretReady) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to prepare secret shares. Please try again.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
        // Clear form only after successful validation
        _nameController.clear();
        _secretController.clear();
        
        // Navigate with additional validation
        if (mounted) {
          Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => const ShareDistributionScreen(),
            ),
          );
        }
      } else {
        // Show error message if creation failed
        if (mounted && secretProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(secretProvider.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      // Handle any unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}