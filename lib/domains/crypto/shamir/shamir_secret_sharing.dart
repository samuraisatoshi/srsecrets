/// Shamir's Secret Sharing Implementation
/// 
/// Complete implementation of Shamir's Secret Sharing scheme with
/// support for single bytes, byte arrays, and strings.
library;

import 'dart:convert';
import 'dart:typed_data';
import '../shares/share.dart';
import '../reconstruction/secret_reconstructor.dart';

/// Main class for Shamir's Secret Sharing operations
class ShamirSecretSharing {
  /// Split a single byte secret into shares
  static SplitResult splitByte({
    required int secret,
    required int threshold,
    required int shares,
  }) {
    if (secret < 0 || secret > 255) {
      throw ArgumentError('Secret must be a byte value (0-255)');
    }
    
    if (threshold < 2) {
      throw ArgumentError('Threshold must be at least 2');
    }
    
    if (threshold > shares) {
      throw ArgumentError('Threshold cannot exceed number of shares');
    }
    
    if (shares > 255) {
      throw ArgumentError('Maximum 255 shares supported in GF(256)');
    }
    
    final shareList = ShareGenerator.generateSecureShares(
      secret: secret,
      threshold: threshold,
      totalShares: shares,
    );
    
    return SplitResult(
      shares: shareList,
      threshold: threshold,
      totalShares: shares,
      metadata: {
        'type': 'byte',
        'created': DateTime.now().toIso8601String(),
      },
    );
  }
  
  /// Split byte array into shares
  static MultiSplitResult splitBytes({
    required Uint8List secret,
    required int threshold,
    required int shares,
  }) {
    if (secret.isEmpty) {
      throw ArgumentError('Secret cannot be empty');
    }
    
    if (threshold < 2) {
      throw ArgumentError('Threshold must be at least 2');
    }
    
    if (threshold > shares) {
      throw ArgumentError('Threshold cannot exceed number of shares');
    }
    
    final shareSets = ShareGenerator.generateShareSets(
      secretBytes: secret,
      threshold: threshold,
      totalShares: shares,
      description: 'Byte array secret',
    );
    
    return MultiSplitResult(
      shareSets: shareSets,
      threshold: threshold,
      totalShares: shares,
      secretLength: secret.length,
      metadata: {
        'type': 'bytes',
        'length': secret.length,
        'created': DateTime.now().toIso8601String(),
      },
    );
  }
  
  /// Split string secret into shares
  static MultiSplitResult splitString({
    required String secret,
    required int threshold,
    required int shares,
  }) {
    if (secret.isEmpty) {
      throw ArgumentError('Secret cannot be empty');
    }
    
    final bytes = Uint8List.fromList(utf8.encode(secret));
    
    final result = splitBytes(
      secret: bytes,
      threshold: threshold,
      shares: shares,
    );
    
    // Update metadata to indicate string type
    result.metadata['type'] = 'string';
    result.metadata['encoding'] = 'utf8';
    
    return result;
  }
  
  /// Combine shares to reconstruct a byte secret
  static int combineByte({
    required List<Share> shares,
    required int threshold,
  }) {
    if (shares.length < threshold) {
      throw ArgumentError(
        'Need at least $threshold shares, got ${shares.length}',
      );
    }
    
    return SecretReconstructor.reconstructSecret(
      shares.take(threshold).toList(),
    );
  }
  
  /// Combine shares to reconstruct byte array
  static Uint8List combineBytes({
    required List<ShareSet> shareSets,
  }) {
    if (shareSets.isEmpty) {
      throw ArgumentError('Share sets cannot be empty');
    }
    
    return SecretReconstructor.reconstructFromShareSets(shareSets);
  }
  
  /// Combine shares to reconstruct string
  static String combineString({
    required List<ShareSet> shareSets,
  }) {
    final bytes = combineBytes(shareSets: shareSets);
    return utf8.decode(bytes);
  }
  
  /// Verify shares without reconstructing the secret
  static bool verifyShares({
    required List<Share> shares,
    required int threshold,
  }) {
    return SecretReconstructor.canReconstruct(shares, threshold);
  }
  
  /// Create a session for interactive operations
  static ShamirSession createSession({
    required int threshold,
    required int totalShares,
  }) {
    return ShamirSession(
      threshold: threshold,
      totalShares: totalShares,
    );
  }
}

/// Result of splitting a single-byte secret
class SplitResult {
  /// Generated shares
  final List<SecureShare> shares;
  
  /// Threshold value
  final int threshold;
  
  /// Total number of shares
  final int totalShares;
  
  /// Additional metadata
  final Map<String, dynamic> metadata;
  
  const SplitResult({
    required this.shares,
    required this.threshold,
    required this.totalShares,
    required this.metadata,
  });
  
  /// Get share at specific index
  SecureShare? getShare(int index) {
    if (index < 0 || index >= shares.length) return null;
    return shares[index];
  }
  
  /// Export shares as JSON
  List<Map<String, dynamic>> toJson() {
    return shares.map((s) => s.toJson()).toList();
  }
  
  /// Export shares as base64 strings
  List<String> toBase64List() {
    return shares.map((s) => s.toBase64()).toList();
  }
}

/// Result of splitting multi-byte secret
class MultiSplitResult {
  /// Generated share sets
  final List<ShareSet> shareSets;
  
  /// Threshold value
  final int threshold;
  
  /// Total number of shares
  final int totalShares;
  
  /// Length of original secret
  final int secretLength;
  
  /// Additional metadata
  final Map<String, dynamic> metadata;
  
  MultiSplitResult({
    required this.shareSets,
    required this.threshold,
    required this.totalShares,
    required this.secretLength,
    required this.metadata,
  });
  
  /// Get share set at index
  ShareSet? getShareSet(int index) {
    if (index < 0 || index >= shareSets.length) return null;
    return shareSets[index];
  }
  
  /// Export as JSON
  List<Map<String, dynamic>> toJson() {
    return shareSets.map((s) => s.toJson()).toList();
  }
  
  /// Export as base64 strings
  List<String> toBase64List() {
    return shareSets.map((s) => s.toBase64()).toList();
  }
  
  /// Create distribution packages for each participant
  List<ParticipantPackage> createDistributionPackages() {
    final packages = <ParticipantPackage>[];
    
    for (int i = 0; i < shareSets.length; i++) {
      packages.add(ParticipantPackage(
        participantNumber: i + 1,
        shareSet: shareSets[i],
        threshold: threshold,
        totalParticipants: totalShares,
      ));
    }
    
    return packages;
  }
}

/// Package for distributing to a participant
class ParticipantPackage {
  /// Participant number (1-based)
  final int participantNumber;
  
  /// The share set for this participant
  final ShareSet shareSet;
  
  /// Threshold needed for reconstruction
  final int threshold;
  
  /// Total number of participants
  final int totalParticipants;
  
  const ParticipantPackage({
    required this.participantNumber,
    required this.shareSet,
    required this.threshold,
    required this.totalParticipants,
  });
  
  /// Export as JSON
  Map<String, dynamic> toJson() {
    return {
      'participantNumber': participantNumber,
      'shareSet': shareSet.toJson(),
      'threshold': threshold,
      'totalParticipants': totalParticipants,
      'instructions': getInstructions(),
    };
  }
  
  /// Get instructions for the participant
  String getInstructions() {
    return '''
Share Package #$participantNumber of $totalParticipants

This package contains your portion of a secret that has been split using 
Shamir's Secret Sharing. To reconstruct the original secret, at least 
$threshold share packages are needed.

IMPORTANT:
- Keep this share package secure and private
- Do not share it unless authorized
- Store it separately from other share packages
- You alone cannot reconstruct the secret

For reconstruction, gather at least $threshold participants with their 
share packages and use the ShamirSecretSharing.combine method.
''';
  }
  
  /// Export as base64 for easy transmission
  String toBase64() {
    final json = jsonEncode(toJson());
    final bytes = utf8.encode(json);
    return base64.encode(bytes);
  }
  
  /// Import from base64
  factory ParticipantPackage.fromBase64(String base64String) {
    final bytes = base64.decode(base64String);
    final json = utf8.decode(bytes);
    final map = jsonDecode(json) as Map<String, dynamic>;
    
    return ParticipantPackage(
      participantNumber: map['participantNumber'] as int,
      shareSet: ShareSet.fromJson(
        map['shareSet'] as Map<String, dynamic>,
      ),
      threshold: map['threshold'] as int,
      totalParticipants: map['totalParticipants'] as int,
    );
  }
}

/// Interactive session for Shamir operations
class ShamirSession {
  /// Configuration
  final int threshold;
  final int totalShares;
  
  /// Current state
  final List<ShareSet> _collectedShares = [];
  bool _isReconstructed = false;
  Uint8List? _reconstructedSecret;
  
  /// Constructor
  ShamirSession({
    required this.threshold,
    required this.totalShares,
  });
  
  /// Add a share set to the session
  bool addShareSet(ShareSet shareSet) {
    // Validate share set
    if (shareSet.metadata.threshold != threshold) {
      throw ArgumentError('Share set has different threshold');
    }
    
    if (shareSet.metadata.totalShares != totalShares) {
      throw ArgumentError('Share set has different total shares');
    }
    
    // Check for duplicate
    final existingIndex = shareSet.metadata.shareIndex;
    if (_collectedShares.any(
      (s) => s.metadata.shareIndex == existingIndex,
    )) {
      return false; // Duplicate share
    }
    
    _collectedShares.add(shareSet);
    
    // Try reconstruction if we have enough shares
    if (_collectedShares.length >= threshold && !_isReconstructed) {
      try {
        _reconstructedSecret = SecretReconstructor.reconstructFromShareSets(
          _collectedShares,
        );
        _isReconstructed = true;
        return true;
      } catch (e) {
        // Not enough valid shares yet
      }
    }
    
    return false;
  }
  
  /// Get current progress
  double get progress => _collectedShares.length / threshold;
  
  /// Check if reconstruction is possible
  bool get canReconstruct => _collectedShares.length >= threshold;
  
  /// Check if already reconstructed
  bool get isReconstructed => _isReconstructed;
  
  /// Get the reconstructed secret
  Uint8List? get secretBytes => _reconstructedSecret;
  
  /// Get reconstructed secret as string
  String? get secretString {
    if (_reconstructedSecret == null) return null;
    try {
      return utf8.decode(_reconstructedSecret!);
    } catch (e) {
      return null; // Not valid UTF-8
    }
  }
  
  /// Get number of shares collected
  int get sharesCollected => _collectedShares.length;
  
  /// Get shares still needed
  int get sharesNeeded {
    final needed = threshold - _collectedShares.length;
    return needed > 0 ? needed : 0;
  }
  
  /// Reset the session
  void reset() {
    _collectedShares.clear();
    _isReconstructed = false;
    _reconstructedSecret = null;
  }
  
  /// Get session status
  Map<String, dynamic> getStatus() {
    return {
      'threshold': threshold,
      'totalShares': totalShares,
      'sharesCollected': sharesCollected,
      'sharesNeeded': sharesNeeded,
      'progress': progress,
      'canReconstruct': canReconstruct,
      'isReconstructed': isReconstructed,
    };
  }
}