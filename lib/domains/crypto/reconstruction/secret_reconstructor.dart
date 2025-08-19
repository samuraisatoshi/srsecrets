/// Secret Reconstruction from Shares
/// 
/// This module handles the reconstruction of secrets from shares
/// using Lagrange interpolation in GF(256).
library;

import 'dart:typed_data';
import '../finite_field/gf256.dart';
import '../shares/share.dart';

/// Reconstructs secrets from shares using Lagrange interpolation
class SecretReconstructor {
  /// Reconstruct a single byte secret from shares
  /// 
  /// Uses Lagrange interpolation to find the constant term
  /// of the polynomial passing through the given points.
  static int reconstructSecret(List<Share> shares) {
    if (shares.isEmpty) {
      throw ArgumentError('Cannot reconstruct from empty shares');
    }
    
    // Validate all shares
    for (final share in shares) {
      if (!share.isValid) {
        throw ArgumentError('Invalid share detected: $share');
      }
    }
    
    // Check for duplicate x values
    final xValues = shares.map((s) => s.x).toSet();
    if (xValues.length != shares.length) {
      throw ArgumentError('Duplicate x values detected in shares');
    }
    
    // Extract x and y coordinates
    final xCoords = shares.map((s) => s.x).toList();
    final yCoords = shares.map((s) => s.y).toList();
    
    // Use Lagrange interpolation to find f(0)
    return GF256.lagrangeInterpolate(xCoords, yCoords);
  }
  
  /// Reconstruct from secure shares with validation
  static int reconstructFromSecureShares(List<SecureShare> shares) {
    if (shares.isEmpty) {
      throw ArgumentError('Cannot reconstruct from empty shares');
    }
    
    // Verify all shares have same threshold and total
    final firstShare = shares.first;
    final threshold = firstShare.threshold;
    final totalShares = firstShare.totalShares;
    
    for (final share in shares) {
      if (share.threshold != threshold) {
        throw ArgumentError(
          'Inconsistent threshold values in shares',
        );
      }
      if (share.totalShares != totalShares) {
        throw ArgumentError(
          'Inconsistent totalShares values in shares',
        );
      }
      if (!share.hasValidHmac) {
        throw ArgumentError(
          'Share failed HMAC verification: $share',
        );
      }
    }
    
    // Check if we have enough shares
    if (shares.length < threshold) {
      throw ArgumentError(
        'Insufficient shares: need $threshold, got ${shares.length}',
      );
    }
    
    // Use only the required number of shares
    final selectedShares = shares.take(threshold).toList();
    
    // Convert to basic shares and reconstruct
    final basicShares = selectedShares
        .map((s) => Share(x: s.x, y: s.y))
        .toList();
    
    return reconstructSecret(basicShares);
  }
  
  /// Reconstruct multi-byte secret from share sets
  static Uint8List reconstructFromShareSets(List<ShareSet> shareSets) {
    if (shareSets.isEmpty) {
      throw ArgumentError('Cannot reconstruct from empty share sets');
    }
    
    // Validate all share sets have same metadata
    final firstSet = shareSets.first;
    final threshold = firstSet.metadata.threshold;
    final totalShares = firstSet.metadata.totalShares;
    final secretLength = firstSet.metadata.secretLength;
    final id = firstSet.metadata.id;
    
    for (final set in shareSets) {
      if (set.metadata.threshold != threshold) {
        throw ArgumentError('Inconsistent threshold in share sets');
      }
      if (set.metadata.totalShares != totalShares) {
        throw ArgumentError('Inconsistent totalShares in share sets');
      }
      if (set.metadata.secretLength != secretLength) {
        throw ArgumentError('Inconsistent secretLength in share sets');
      }
      if (set.metadata.id != id) {
        throw ArgumentError('Share sets have different IDs');
      }
    }
    
    // Check if we have enough share sets
    if (shareSets.length < threshold) {
      throw ArgumentError(
        'Insufficient share sets: need $threshold, got ${shareSets.length}',
      );
    }
    
    // Reconstruct each byte position
    final reconstructedBytes = Uint8List(secretLength);
    
    for (int byteIndex = 0; byteIndex < secretLength; byteIndex++) {
      // Collect shares for this byte position
      final sharesForByte = <Share>[];
      
      for (final set in shareSets.take(threshold)) {
        final share = set.shares[byteIndex];
        sharesForByte.add(share);
      }
      
      // Reconstruct this byte
      reconstructedBytes[byteIndex] = reconstructSecret(sharesForByte);
    }
    
    return reconstructedBytes;
  }
  
  /// Verify that shares can reconstruct to a valid secret
  /// without actually revealing the secret
  static bool canReconstruct(List<Share> shares, int threshold) {
    if (shares.length < threshold) {
      return false;
    }
    
    // Check for valid shares
    for (final share in shares) {
      if (!share.isValid) {
        return false;
      }
    }
    
    // Check for unique x values
    final xValues = shares.map((s) => s.x).toSet();
    if (xValues.length != shares.length) {
      return false;
    }
    
    return true;
  }
  
  /// Reconstruct with error detection
  /// 
  /// Uses redundant shares to detect errors in reconstruction
  static ReconstructionResult reconstructWithVerification({
    required List<Share> shares,
    required int threshold,
  }) {
    if (shares.length < threshold) {
      return ReconstructionResult(
        success: false,
        error: 'Insufficient shares for reconstruction',
      );
    }
    
    // Try reconstruction with minimum shares
    final minimalShares = shares.take(threshold).toList();
    int reconstructedSecret;
    
    try {
      reconstructedSecret = reconstructSecret(minimalShares);
    } catch (e) {
      return ReconstructionResult(
        success: false,
        error: 'Reconstruction failed: $e',
      );
    }
    
    // If we have extra shares, verify consistency
    if (shares.length > threshold) {
      final verificationResults = <int>[];
      
      // Try different combinations of shares
      for (int i = 0; i <= shares.length - threshold; i++) {
        final subset = shares.skip(i).take(threshold).toList();
        try {
          final result = reconstructSecret(subset);
          verificationResults.add(result);
        } catch (e) {
          // Ignore errors in verification subsets
        }
      }
      
      // Check if all reconstructions match
      final allMatch = verificationResults.every(
        (r) => r == reconstructedSecret,
      );
      
      if (!allMatch) {
        return ReconstructionResult(
          success: false,
          error: 'Inconsistent reconstruction results - possible corrupted shares',
        );
      }
    }
    
    return ReconstructionResult(
      success: true,
      secret: reconstructedSecret,
    );
  }
  
  /// Progressive reconstruction with partial shares
  /// 
  /// Attempts reconstruction as shares are added incrementally
  static ProgressiveReconstructor createProgressive({
    required int threshold,
  }) {
    return ProgressiveReconstructor(threshold: threshold);
  }
}

/// Result of secret reconstruction
class ReconstructionResult {
  /// Whether reconstruction was successful
  final bool success;
  
  /// The reconstructed secret (if successful)
  final int? secret;
  
  /// Error message (if failed)
  final String? error;
  
  /// Additional metadata
  final Map<String, dynamic>? metadata;
  
  const ReconstructionResult({
    required this.success,
    this.secret,
    this.error,
    this.metadata,
  });
}

/// Progressive reconstructor for incremental share addition
class ProgressiveReconstructor {
  /// Required threshold for reconstruction
  final int threshold;
  
  /// Currently accumulated shares
  final List<Share> _shares = [];
  
  /// Whether reconstruction has succeeded
  bool _reconstructed = false;
  
  /// The reconstructed secret (once available)
  int? _secret;
  
  /// Constructor
  ProgressiveReconstructor({required this.threshold});
  
  /// Add a share to the reconstructor
  bool addShare(Share share) {
    // Validate share
    if (!share.isValid) {
      throw ArgumentError('Invalid share: $share');
    }
    
    // Check for duplicate x value
    if (_shares.any((s) => s.x == share.x)) {
      return false; // Duplicate share
    }
    
    _shares.add(share);
    
    // Try reconstruction if we have enough shares
    if (_shares.length >= threshold && !_reconstructed) {
      try {
        _secret = SecretReconstructor.reconstructSecret(
          _shares.take(threshold).toList(),
        );
        _reconstructed = true;
        return true;
      } catch (e) {
        // Reconstruction failed, need more/different shares
      }
    }
    
    return _reconstructed;
  }
  
  /// Get the current number of shares
  int get shareCount => _shares.length;
  
  /// Check if reconstruction is complete
  bool get isComplete => _reconstructed;
  
  /// Get the reconstructed secret
  int? get secret => _secret;
  
  /// Get progress as percentage
  double get progress {
    if (_reconstructed) return 1.0;
    return _shares.length / threshold;
  }
  
  /// Reset the reconstructor
  void reset() {
    _shares.clear();
    _reconstructed = false;
    _secret = null;
  }
  
  /// Get current shares
  List<Share> get shares => List.unmodifiable(_shares);
}

/// Batch reconstructor for multiple secrets
class BatchReconstructor {
  /// Reconstruct multiple single-byte secrets
  static List<int> reconstructMultiple({
    required List<List<Share>> shareGroups,
    required int threshold,
  }) {
    final results = <int>[];
    
    for (final shares in shareGroups) {
      if (shares.length < threshold) {
        throw ArgumentError(
          'Insufficient shares in group: need $threshold, got ${shares.length}',
        );
      }
      
      results.add(
        SecretReconstructor.reconstructSecret(
          shares.take(threshold).toList(),
        ),
      );
    }
    
    return results;
  }
  
  /// Reconstruct with parallel processing (if available)
  static Future<List<int>> reconstructParallel({
    required List<List<Share>> shareGroups,
    required int threshold,
  }) async {
    // In a real implementation, this could use isolates
    // for parallel processing of large batches
    return reconstructMultiple(
      shareGroups: shareGroups,
      threshold: threshold,
    );
  }
}