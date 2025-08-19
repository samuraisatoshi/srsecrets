import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../domains/crypto/shamir/shamir_secret_sharing.dart';
import '../../domains/crypto/shares/share.dart';

class SecretInfo {
  final String id;
  final String name;
  final DateTime createdAt;
  final int threshold;
  final int totalShares;
  final String type; // 'text', 'bytes', 'file'

  SecretInfo({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.threshold,
    required this.totalShares,
    required this.type,
  });
}

class SecretProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  final List<SecretInfo> _secrets = [];
  
  // Current operation states
  MultiSplitResult? _lastResult;
  String? _reconstructedSecret;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SecretInfo> get secrets => _secrets;
  MultiSplitResult? get lastResult => _lastResult;
  String? get reconstructedSecret => _reconstructedSecret;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Create secret shares
  Future<bool> createSecret({
    required String secretName,
    required String secret,
    required int threshold,
    required int totalShares,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = ShamirSecretSharing.splitString(
        secret: secret,
        threshold: threshold,
        shares: totalShares,
      );

      _lastResult = result;
      
      // Verify the result was created successfully
      if (result.shareSets.isEmpty) {
        _setError('Failed to generate shares');
        _setLoading(false);
        return false;
      }
      
      // Create secret info for local storage
      final secretInfo = SecretInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: secretName,
        createdAt: DateTime.now(),
        threshold: threshold,
        totalShares: totalShares,
        type: 'text',
      );

      _secrets.add(secretInfo);
      
      // Ensure listeners are notified before navigation
      notifyListeners();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create secret shares: $e');
      _setLoading(false);
      return false;
    }
  }

  // Reconstruct secret from shares
  Future<bool> reconstructSecret(List<String> shareStrings) async {
    _setLoading(true);
    _clearError();

    try {
      // Parse share strings into ShareSet objects
      final shareSets = shareStrings.map((shareString) {
        // Try to parse as JSON first, then as base64
        try {
          // Parse JSON string to Map first
          final jsonMap = json.decode(shareString) as Map<String, dynamic>;
          return ShareSet.fromJson(jsonMap);
        } catch (_) {
          // If JSON parsing fails, try base64
          return ShareSet.fromBase64(shareString);
        }
      }).toList();

      final secret = ShamirSecretSharing.combineString(shareSets: shareSets);
      
      if (secret.isNotEmpty) {
        _reconstructedSecret = secret;
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to reconstruct secret. Please check your shares.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error reconstructing secret: $e');
      _setLoading(false);
      return false;
    }
  }

  // Clear current operation results
  void clearResults() {
    _lastResult = null;
    _reconstructedSecret = null;
    notifyListeners();
  }

  // Remove a secret from the list
  void removeSecret(String id) {
    _secrets.removeWhere((secret) => secret.id == id);
    notifyListeners();
  }

  // Get distribution packages for sharing
  List<ParticipantPackage> getDistributionPackages() {
    if (_lastResult == null) return [];
    return _lastResult!.createDistributionPackages();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}