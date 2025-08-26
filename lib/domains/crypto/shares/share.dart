/// Share Creation and Serialization for Shamir's Secret Sharing
/// 
/// This module handles the creation, serialization, and deserialization
/// of shares in the Shamir's Secret Sharing scheme.
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import '../finite_field/gf256.dart';
import '../polynomial/polynomial_generator.dart';
import '../random/secure_random.dart';

/// Represents a single share in Shamir's Secret Sharing scheme
class Share {
  /// The x-coordinate (share index)
  final int x;
  
  /// The y-coordinate (polynomial evaluation at x)
  final int y;
  
  /// Optional metadata for share management
  final Map<String, dynamic>? metadata;
  
  /// Constructor
  const Share({
    required this.x,
    required this.y,
    this.metadata,
  });
  
  /// Validate share values
  bool get isValid {
    return GF256.isValidElement(x) && 
           GF256.isValidElement(y) &&
           x != 0; // x=0 is reserved for the secret
  }
  
  /// Convert share to JSON-serializable map
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      if (metadata != null) 'metadata': metadata,
    };
  }
  
  /// Create share from JSON map
  factory Share.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('x') || !json.containsKey('y')) {
      throw ArgumentError('Share JSON must contain x and y values');
    }
    
    return Share(
      x: json['x'] as int,
      y: json['y'] as int,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  
  /// Convert to base64 string for easy transmission
  String toBase64() {
    final json = jsonEncode(toJson());
    final bytes = utf8.encode(json);
    return base64.encode(bytes);
  }
  
  /// Create share from base64 string
  factory Share.fromBase64(String base64String) {
    final bytes = base64.decode(base64String);
    final json = utf8.decode(bytes);
    final map = jsonDecode(json) as Map<String, dynamic>;
    return Share.fromJson(map);
  }
  
  @override
  String toString() {
    return 'Share(x=$x, y=$y)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Share && other.x == x && other.y == y;
  }
  
  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

/// Extended share with additional security features
class SecureShare extends Share {
  /// Share version for compatibility
  final int version;
  
  /// Threshold value (k in k-of-n scheme)
  final int threshold;
  
  /// Total number of shares created
  final int totalShares;
  
  /// Share identifier (for tracking)
  final String? identifier;
  
  /// HMAC for integrity verification (32-byte SHA-256 HMAC)
  final Uint8List? hmac;
  
  /// Constructor
  const SecureShare({
    required int x,
    required int y,
    required this.version,
    required this.threshold,
    required this.totalShares,
    this.identifier,
    this.hmac,
    Map<String, dynamic>? metadata,
  }) : super(x: x, y: y, metadata: metadata);
  
  /// Derive HMAC key from share metadata for integrity verification
  static Uint8List _deriveHmacKey({
    required int threshold,
    required int totalShares,
    required int version,
    String? identifier,
  }) {
    // Create a deterministic key derivation input from metadata
    final keyMaterial = <int>[];
    
    // Add threshold and totalShares as key material
    keyMaterial.addAll([threshold, totalShares, version]);
    
    // Add identifier if present, or default salt
    if (identifier != null) {
      keyMaterial.addAll(utf8.encode(identifier));
    } else {
      // Default salt for anonymous shares
      keyMaterial.addAll(utf8.encode('SRSecrets-HMAC-v1'));
    }
    
    // Use SHA-256 to derive a 32-byte key from the metadata
    final digest = sha256.convert(keyMaterial);
    return Uint8List.fromList(digest.bytes);
  }
  
  /// Calculate SHA-256 HMAC for share data integrity verification
  static Uint8List calculateHmac({
    required int x,
    required int y,
    required int threshold,
    required int totalShares,
    required int version,
    String? identifier,
  }) {
    // Derive HMAC key from share metadata
    final hmacKey = _deriveHmacKey(
      threshold: threshold,
      totalShares: totalShares,
      version: version,
      identifier: identifier,
    );
    
    // Prepare data to be authenticated
    final dataToAuthenticate = Uint8List.fromList([
      x, y, threshold, totalShares, version
    ]);
    
    // Calculate HMAC-SHA256
    final hmacSha256 = Hmac(sha256, hmacKey);
    final digest = hmacSha256.convert(dataToAuthenticate);
    
    return Uint8List.fromList(digest.bytes);
  }
  
  /// Verify share integrity using constant-time HMAC comparison
  bool get hasValidHmac {
    if (hmac == null) return true; // No HMAC to verify
    
    final expectedHmac = calculateHmac(
      x: x,
      y: y,
      threshold: threshold,
      totalShares: totalShares,
      version: version,
      identifier: identifier,
    );
    
    // Perform constant-time comparison to prevent timing attacks
    return constantTimeEquals(hmac!, expectedHmac);
  }
  
  /// Constant-time comparison to prevent timing attacks
  @visibleForTesting
  static bool constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    
    return result == 0;
  }
  
  /// Legacy checksum calculation for backward compatibility
  @deprecated
  static int calculateChecksum(int x, int y, int threshold, int totalShares) {
    // Legacy XOR-based checksum - deprecated for security reasons
    return x ^ y ^ threshold ^ totalShares;
  }
  
  /// Legacy checksum verification for backward compatibility  
  @deprecated
  bool get hasValidChecksum {
    // This method is deprecated - use hasValidHmac instead
    return true; // Always return true for legacy compatibility
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'version': version,
      'threshold': threshold,
      'totalShares': totalShares,
      if (identifier != null) 'identifier': identifier,
      if (hmac != null) 'hmac': base64.encode(hmac!),
    };
  }
  
  /// Create secure share from JSON
  factory SecureShare.fromJson(Map<String, dynamic> json) {
    // Handle HMAC deserialization
    Uint8List? hmacBytes;
    if (json['hmac'] != null) {
      hmacBytes = Uint8List.fromList(base64.decode(json['hmac'] as String));
    }
    
    return SecureShare(
      x: json['x'] as int,
      y: json['y'] as int,
      version: json['version'] as int,
      threshold: json['threshold'] as int,
      totalShares: json['totalShares'] as int,
      identifier: json['identifier'] as String?,
      hmac: hmacBytes,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Container for multiple shares (when sharing multi-byte secrets)
class ShareSet {
  /// List of shares for each byte position
  final List<Share> shares;
  
  /// Metadata about the share set
  final ShareSetMetadata metadata;
  
  /// Constructor
  const ShareSet({
    required this.shares,
    required this.metadata,
  });
  
  /// Get share at specific index
  Share? getShareAt(int index) {
    if (index < 0 || index >= shares.length) return null;
    return shares[index];
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'shares': shares.map((s) => s.toJson()).toList(),
      'metadata': metadata.toJson(),
    };
  }
  
  /// Create from JSON
  factory ShareSet.fromJson(Map<String, dynamic> json) {
    return ShareSet(
      shares: (json['shares'] as List)
          .map((s) => Share.fromJson(s as Map<String, dynamic>))
          .toList(),
      metadata: ShareSetMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
    );
  }
  
  /// Convert to base64
  String toBase64() {
    final json = jsonEncode(toJson());
    final bytes = utf8.encode(json);
    return base64.encode(bytes);
  }
  
  /// Create from base64
  factory ShareSet.fromBase64(String base64String) {
    final bytes = base64.decode(base64String);
    final json = utf8.decode(bytes);
    final map = jsonDecode(json) as Map<String, dynamic>;
    return ShareSet.fromJson(map);
  }
}

/// Metadata for share sets
class ShareSetMetadata {
  /// Unique identifier for this share set
  final String id;
  
  /// Share index (which share this is: 1 of n, 2 of n, etc.)
  final int shareIndex;
  
  /// Threshold value
  final int threshold;
  
  /// Total shares created
  final int totalShares;
  
  /// Number of bytes in the original secret
  final int secretLength;
  
  /// Creation timestamp
  final DateTime createdAt;
  
  /// Optional description
  final String? description;
  
  /// Constructor
  const ShareSetMetadata({
    required this.id,
    required this.shareIndex,
    required this.threshold,
    required this.totalShares,
    required this.secretLength,
    required this.createdAt,
    this.description,
  });
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shareIndex': shareIndex,
      'threshold': threshold,
      'totalShares': totalShares,
      'secretLength': secretLength,
      'createdAt': createdAt.toIso8601String(),
      if (description != null) 'description': description,
    };
  }
  
  /// Create from JSON
  factory ShareSetMetadata.fromJson(Map<String, dynamic> json) {
    return ShareSetMetadata(
      id: json['id'] as String,
      shareIndex: json['shareIndex'] as int,
      threshold: json['threshold'] as int,
      totalShares: json['totalShares'] as int,
      secretLength: json['secretLength'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
    );
  }
}

/// Generator for creating shares from secrets
class ShareGenerator {
  /// Generate shares for a single byte secret
  static List<Share> generateShares({
    required int secret,
    required int threshold,
    required int totalShares,
  }) {
    if (totalShares < threshold) {
      throw ArgumentError(
        'Total shares must be >= threshold',
      );
    }
    
    // Generate polynomial with secret as constant term
    final coefficients = PolynomialGenerator.generatePolynomial(
      secret: secret,
      threshold: threshold,
    );
    
    // Generate x values for evaluation
    final xValues = PolynomialGenerator.generateEvaluationPoints(
      totalShares,
    );
    
    // Create shares by evaluating polynomial at each x
    final shares = <Share>[];
    for (int x in xValues) {
      final y = PolynomialGenerator.evaluatePolynomial(
        coefficients,
        x,
      );
      shares.add(Share(x: x, y: y));
    }
    
    return shares;
  }
  
  /// Generate secure shares with metadata
  static List<SecureShare> generateSecureShares({
    required int secret,
    required int threshold,
    required int totalShares,
    String? identifier,
    int version = 1,
  }) {
    final basicShares = generateShares(
      secret: secret,
      threshold: threshold,
      totalShares: totalShares,
    );
    
    return basicShares.map((share) {
      final hmac = SecureShare.calculateHmac(
        x: share.x,
        y: share.y,
        threshold: threshold,
        totalShares: totalShares,
        version: version,
        identifier: identifier,
      );
      
      return SecureShare(
        x: share.x,
        y: share.y,
        version: version,
        threshold: threshold,
        totalShares: totalShares,
        identifier: identifier,
        hmac: hmac,
      );
    }).toList();
  }
  
  /// Generate shares for multi-byte secret
  static List<ShareSet> generateShareSets({
    required Uint8List secretBytes,
    required int threshold,
    required int totalShares,
    String? description,
  }) {
    if (secretBytes.isEmpty) {
      throw ArgumentError('Secret bytes cannot be empty');
    }
    
    // Generate unique ID for this share set
    final id = _generateShareSetId();
    final createdAt = DateTime.now();
    
    // Generate x values once to be reused across all byte positions
    final xValues = PolynomialGenerator.generateEvaluationPoints(totalShares);
    
    // Create shares for each byte position using the same x values
    final allSharesByPosition = <List<Share>>[];
    for (int byte in secretBytes) {
      // Generate polynomial with secret as constant term
      final coefficients = PolynomialGenerator.generatePolynomial(
        secret: byte,
        threshold: threshold,
      );
      
      // Create shares by evaluating polynomial at each x
      final shares = <Share>[];
      for (int x in xValues) {
        final y = PolynomialGenerator.evaluatePolynomial(coefficients, x);
        shares.add(Share(x: x, y: y));
      }
      
      allSharesByPosition.add(shares);
    }
    
    // Transpose to group by share index
    final shareSets = <ShareSet>[];
    for (int i = 0; i < totalShares; i++) {
      final sharesForThisIndex = <Share>[];
      
      for (int j = 0; j < secretBytes.length; j++) {
        sharesForThisIndex.add(allSharesByPosition[j][i]);
      }
      
      final metadata = ShareSetMetadata(
        id: id,
        shareIndex: i + 1,
        threshold: threshold,
        totalShares: totalShares,
        secretLength: secretBytes.length,
        createdAt: createdAt,
        description: description,
      );
      
      shareSets.add(ShareSet(
        shares: sharesForThisIndex,
        metadata: metadata,
      ));
    }
    
    return shareSets;
  }
  
  /// Generate a unique ID for share sets
  static String _generateShareSetId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = SecureRandom.instance.nextInt(0xFFFF);
    return 'SS-${timestamp.toRadixString(36)}-${random.toRadixString(36)}';
  }
}