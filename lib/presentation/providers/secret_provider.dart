import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../domains/crypto/shamir/shamir_secret_sharing.dart';
import '../../domains/crypto/shares/share.dart';
import '../../domains/storage/repositories/secret_storage_repository.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'threshold': threshold,
      'totalShares': totalShares,
      'type': type,
    };
  }

  factory SecretInfo.fromMap(Map<String, dynamic> map) {
    return SecretInfo(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
      threshold: map['threshold'],
      totalShares: map['totalShares'],
      type: map['type'],
    );
  }
}

class SecretProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  final List<SecretInfo> _secrets = [];
  final SecretStorageRepository _storageRepository = SecretStorageRepository();
  
  // Current operation states
  MultiSplitResult? _lastResult;
  String? _reconstructedSecret;

  // Constructor - load saved secrets
  SecretProvider() {
    _loadSecrets();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SecretInfo> get secrets => _secrets;
  MultiSplitResult? get lastResult => _lastResult;
  String? get reconstructedSecret => _reconstructedSecret;

  // Load secrets from storage
  Future<void> _loadSecrets() async {
    try {
      final savedSecrets = await _storageRepository.loadSecrets();
      _secrets.clear();
      for (final secretMap in savedSecrets) {
        _secrets.add(SecretInfo.fromMap(secretMap));
      }
      notifyListeners();
    } catch (e) {
      // Silently fail - just use empty list
    }
  }

  // Save secrets to storage
  Future<void> _saveSecrets() async {
    try {
      final secretMaps = _secrets.map((s) => s.toMap()).toList();
      await _storageRepository.saveSecrets(secretMaps);
    } catch (e) {
      // Silently fail - at least keep in memory
    }
  }

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
      // Input validation
      if (secretName.trim().isEmpty) {
        _setError('Secret name cannot be empty');
        _setLoading(false);
        return false;
      }
      
      if (secret.trim().isEmpty) {
        _setError('Secret cannot be empty');
        _setLoading(false);
        return false;
      }
      
      final result = ShamirSecretSharing.splitString(
        secret: secret,
        threshold: threshold,
        shares: totalShares,
      );

      // Validate result before setting
      if (result.shareSets.isEmpty) {
        _setError('Failed to generate shares: No share sets created');
        _setLoading(false);
        return false;
      }
      
      // Double-check that distribution packages can be created
      try {
        final testPackages = result.createDistributionPackages();
        if (testPackages.isEmpty) {
          _setError('Failed to create distribution packages');
          _setLoading(false);
          return false;
        }
      } catch (e) {
        _setError('Failed to validate distribution packages: $e');
        _setLoading(false);
        return false;
      }
      
      // Set result only after validation
      _lastResult = result;
      
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
      
      // Save to persistent storage
      await _saveSecrets();
      
      // Update state
      _setLoading(false);
      
      return true;
    } catch (e) {
      _setError('Failed to create secret shares: $e');
      _setLoading(false);
      return false;
    }
  }

  // Reconstruct secret from shares
  bool reconstructSecret(List<String> shareStrings) {
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
  Future<void> removeSecret(String id) async {
    _secrets.removeWhere((secret) => secret.id == id);
    await _saveSecrets();
    notifyListeners();
  }

  // Get distribution packages for sharing with enhanced error handling
  List<ParticipantPackage> getDistributionPackages() {
    if (_lastResult == null) {
      return [];
    }
    
    try {
      final packages = _lastResult!.createDistributionPackages();
      return packages;
    } catch (e) {
      _setError('Failed to create distribution packages: $e');
      return [];
    }
  }
  
  // Safe distribution packages getter that preserves state during UI operations
  List<ParticipantPackage> getSafeDistributionPackages() {
    // Return cached packages to avoid state clearing issues
    if (_lastResult != null) {
      try {
        return _lastResult!.createDistributionPackages();
      } catch (e) {
        return [];
      }
    }
    return [];
  }
  
  // Validate that secret creation completed successfully
  bool get isSecretReady {
    if (_lastResult == null) return false;
    if (_lastResult!.shareSets.isEmpty) return false;
    
    try {
      final packages = _lastResult!.createDistributionPackages();
      return packages.isNotEmpty;
    } catch (e) {
      return false;
    }
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