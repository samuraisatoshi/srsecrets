import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/pin_storage_diagnostic.dart';
import '../../domains/auth/repositories/secure_storage_repository.dart';

class DebugStorageScreen extends StatefulWidget {
  const DebugStorageScreen({super.key});

  @override
  State<DebugStorageScreen> createState() => _DebugStorageScreenState();
}

class _DebugStorageScreenState extends State<DebugStorageScreen> {
  Map<String, dynamic>? _diagnosticReport;
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Running diagnostic...';
    });

    try {
      final report = await PinStorageDiagnostic.checkAllStorageLocations();
      setState(() {
        _diagnosticReport = report;
        _statusMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Diagnostic failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanupStorage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Storage Cleanup'),
        content: const Text(
          'This will delete ALL PIN data from all storage locations. '
          'You will need to set up a new PIN after this. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Cleaning up storage...';
    });

    try {
      final result = await PinStorageDiagnostic.cleanupAllStorageLocations();
      
      setState(() {
        _statusMessage = result['success'] == true
            ? 'Storage cleaned successfully'
            : 'Cleanup completed with errors';
        _isLoading = false;
      });

      // Refresh diagnostic
      await _runDiagnostic();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['success'] == true
                  ? 'All PIN data has been cleared'
                  : 'Cleanup completed with some errors',
            ),
            backgroundColor: result['success'] == true ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Cleanup failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _forceClearViaRepository() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Clear via Repository'),
        content: const Text(
          'This will use the repository\'s force clear method to remove all PIN data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Force Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Force clearing via repository...';
    });

    try {
      final repository = SecureStorageRepository();
      await repository.forceClearAllStorageLocations();
      
      setState(() {
        _statusMessage = 'Force clear completed';
        _isLoading = false;
      });

      // Refresh diagnostic
      await _runDiagnostic();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repository force clear completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Force clear failed: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    final bool exists = location['exists'] ?? false;
    final List files = location['files'] ?? [];
    final String? warning = location['warning'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(
          location['name'] ?? 'Unknown',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: warning != null ? Colors.orange : null,
          ),
        ),
        subtitle: Text(
          exists ? 'Directory exists (${files.length} files)' : 'Directory does not exist',
          style: TextStyle(
            color: exists ? Colors.green : Colors.grey,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Path:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  location['path'] ?? 'Unknown',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                if (warning != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            warning,
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (files.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Files:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...files.map((file) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          file['name'] ?? 'Unknown',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${file['size']} bytes)',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = PinStorageDiagnostic.getStorageRecommendations();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Diagnostic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _runDiagnostic,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage ?? 'Loading...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform Info Card
                  Card(
                    color: Colors.blue.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Platform Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Platform: ${_diagnosticReport?['platform'] ?? 'Unknown'}'),
                          const SizedBox(height: 4),
                          Text('Recommendation: ${recommendations['recommendation']}'),
                          const SizedBox(height: 4),
                          Text(
                            'Reason: ${recommendations['reason']}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Storage Locations
                  const Text(
                    'Storage Locations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_diagnosticReport != null && _diagnosticReport!['locations'] != null)
                    ...(_diagnosticReport!['locations'] as List).map(
                      (location) => _buildLocationCard(location as Map<String, dynamic>),
                    ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _cleanupStorage,
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Clean All Storage Locations'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _forceClearViaRepository,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Force Clear via Repository'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Copy diagnostic report to clipboard
                        final report = _diagnosticReport?.toString() ?? 'No report available';
                        Clipboard.setData(ClipboardData(text: report));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Diagnostic report copied to clipboard'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Report to Clipboard'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  if (_statusMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_statusMessage!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}