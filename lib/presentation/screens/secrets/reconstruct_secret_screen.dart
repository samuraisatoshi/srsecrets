import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/secret_provider.dart';
import '../../widgets/secret_form_header.dart';
import '../../widgets/share_input_widget.dart';
import '../../widgets/error_display_widget.dart';

class ReconstructSecretScreen extends StatefulWidget {
  const ReconstructSecretScreen({super.key});

  @override
  State<ReconstructSecretScreen> createState() => _ReconstructSecretScreenState();
}

class _ReconstructSecretScreenState extends State<ReconstructSecretScreen> {
  final List<TextEditingController> _shareControllers = [];
  final List<FocusNode> _focusNodes = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _shareCount = 3;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _shareControllers.clear();
    _focusNodes.clear();
    
    for (int i = 0; i < _shareCount; i++) {
      _shareControllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final controller in _shareControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _addShare() {
    if (_shareCount < 10) {
      setState(() {
        _shareCount++;
        _shareControllers.add(TextEditingController());
        _focusNodes.add(FocusNode());
      });
    }
  }

  void _removeShare(int index) {
    if (_shareCount > 2) {
      setState(() {
        _shareControllers[index].dispose();
        _focusNodes[index].dispose();
        _shareControllers.removeAt(index);
        _focusNodes.removeAt(index);
        _shareCount--;
      });
    }
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
        ? (constraints.maxWidth > 900 ? 900.0 : constraints.maxWidth)
        : constraints.maxWidth;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            const SecretFormHeader(
              title: 'Reconstruct Secret',
              subtitle: 'Enter the required number of shares to reconstruct your original secret',
              icon: Icons.restore,
              infoText: 'You need at least k shares (threshold) to reconstruct the secret',
            ),
            SizedBox(height: isTablet ? 24 : 16),
            
            // Shares section
            if (isTablet && isLandscape && _shareCount <= 4)
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
        // Share input fields
        ...List.generate(_shareCount, (i) => 
          ShareInputWidget(
            controller: _shareControllers[i],
            focusNode: _focusNodes[i],
            index: i,
            canRemove: _shareCount > 2,
            onRemove: () => _removeShare(i),
            onPaste: () => _pasteShare(i),
          ),
        ),
        
        // Add share button
        SizedBox(height: isTablet ? 20 : 16),
        Semantics(
          label: 'Add another share input',
          hint: 'Adds a new field to enter additional secret share',
          button: true,
          child: OutlinedButton.icon(
            onPressed: _shareCount >= 10 ? null : _addShare,
            icon: const Icon(Icons.add),
            label: const Text('Add Share'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 24,
                vertical: isTablet ? 16 : 12,
              ),
            ),
          ),
        ),
        
        SizedBox(height: isTablet ? 32 : 24),
        
        // Error message
        if (secretProvider.errorMessage != null)
          ErrorDisplayWidget(
            errorMessage: secretProvider.errorMessage!,
            onDismiss: secretProvider.clearError,
          ),
        
        // Reconstruct button
        SizedBox(
          width: double.infinity,
          height: isTablet ? 56 : 48,
          child: Semantics(
            label: 'Reconstruct secret from shares',
            hint: 'Combines the entered shares to reconstruct the original secret',
            button: true,
            child: ElevatedButton(
              onPressed: secretProvider.isLoading ? null : _reconstructSecret,
              child: secretProvider.isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'Reconstructing secret',
                      ),
                    )
                  : Text(
                      'Reconstruct Secret',
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
    // For landscape tablet with few shares, show them in a grid
    final shareWidgets = List.generate(_shareCount, (i) => 
      ShareInputWidget(
        controller: _shareControllers[i],
        focusNode: _focusNodes[i],
        index: i,
        canRemove: _shareCount > 2,
        onRemove: () => _removeShare(i),
        onPaste: () => _pasteShare(i),
      ),
    );

    return Column(
      children: [
        // Share inputs in a responsive grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 24,
          children: shareWidgets,
        ),
        
        const SizedBox(height: 24),
        
        // Controls row
        Row(
          children: [
            Semantics(
              label: 'Add another share input',
              hint: 'Adds a new field to enter additional secret share',
              button: true,
              child: OutlinedButton.icon(
                onPressed: _shareCount >= 10 ? null : _addShare,
                icon: const Icon(Icons.add),
                label: const Text('Add Share'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 200,
              height: 56,
              child: Semantics(
                label: 'Reconstruct secret from shares',
                hint: 'Combines the entered shares to reconstruct the original secret',
                button: true,
                child: ElevatedButton(
                  onPressed: secretProvider.isLoading ? null : _reconstructSecret,
                  child: secretProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: 'Reconstructing secret',
                          ),
                        )
                      : const Text(
                          'Reconstruct Secret',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Error message
        if (secretProvider.errorMessage != null)
          ErrorDisplayWidget(
            errorMessage: secretProvider.errorMessage!,
            onDismiss: secretProvider.clearError,
          ),
      ],
    );
  }

  Future<void> _pasteShare(int index) async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        _shareControllers[index].text = clipboardData!.text!;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to paste: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }


  Future<void> _reconstructSecret() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final shares = _shareControllers
        .map((controller) => controller.text.trim())
        .where((share) => share.isNotEmpty)
        .toList();

    if (shares.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 2 shares'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final secretProvider = context.read<SecretProvider>();
    final success = await secretProvider.reconstructSecret(shares);

    if (success && mounted) {
      _showReconstructedSecret(secretProvider.reconstructedSecret!);
      // Clear form
      for (final controller in _shareControllers) {
        controller.clear();
      }
    }
  }

  void _showReconstructedSecret(String secret) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Secret Reconstructed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your secret has been successfully reconstructed:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: SelectableText(
                secret,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Save your secret now - it will not be stored',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: secret));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Secret copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SecretProvider>().clearResults();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}