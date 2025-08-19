/// PIN Hash Model for Authentication Domain
/// 
/// Represents a securely hashed PIN with associated metadata.
/// Uses PBKDF2 for secure key derivation.
library;

import 'dart:typed_data';

/// Represents a hashed PIN with salt and iteration metadata
/// Immutable value object following DDD principles
class PinHash {
  /// The PBKDF2 hash of the PIN
  final Uint8List hash;
  
  /// The cryptographic salt used for hashing
  final Uint8List salt;
  
  /// Number of PBKDF2 iterations used
  final int iterations;
  
  /// Hash algorithm identifier for future compatibility
  final String algorithm;
  
  /// Creation timestamp for security auditing
  final DateTime createdAt;
  
  /// Private constructor to ensure proper validation
  const PinHash._({
    required this.hash,
    required this.salt,
    required this.iterations,
    required this.algorithm,
    required this.createdAt,
  });
  
  /// Create a new PinHash with validation
  factory PinHash.create({
    required Uint8List hash,
    required Uint8List salt,
    required int iterations,
    String algorithm = 'PBKDF2-SHA256',
    DateTime? createdAt,
  }) {
    if (hash.isEmpty) {
      throw ArgumentError('Hash cannot be empty');
    }
    
    if (salt.isEmpty) {
      throw ArgumentError('Salt cannot be empty');
    }
    
    if (iterations <= 0) {
      throw ArgumentError('Iterations must be positive');
    }
    
    if (algorithm.isEmpty) {
      throw ArgumentError('Algorithm cannot be empty');
    }
    
    return PinHash._(
      hash: Uint8List.fromList(hash),
      salt: Uint8List.fromList(salt),
      iterations: iterations,
      algorithm: algorithm,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
  
  /// Create PinHash from storage format
  factory PinHash.fromMap(Map<String, dynamic> map) {
    return PinHash.create(
      hash: Uint8List.fromList(List<int>.from(map['hash'])),
      salt: Uint8List.fromList(List<int>.from(map['salt'])),
      iterations: map['iterations'] as int,
      algorithm: map['algorithm'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
  
  /// Convert to storage format
  Map<String, dynamic> toMap() {
    return {
      'hash': hash.toList(),
      'salt': salt.toList(),
      'iterations': iterations,
      'algorithm': algorithm,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  /// Verify if this hash was created with sufficient security parameters
  bool isSecure() {
    // Minimum security requirements
    const int minIterations = 100000;  // NIST recommendation
    const int minSaltLength = 16;      // 128 bits
    const int minHashLength = 32;      // 256 bits
    
    return iterations >= minIterations &&
           salt.length >= minSaltLength &&
           hash.length >= minHashLength &&
           algorithm == 'PBKDF2-SHA256';
  }
  
  /// Check if hash needs to be upgraded due to security requirements
  bool needsUpgrade() {
    const int recommendedIterations = 200000;  // Current recommendation
    const Duration maxAge = Duration(days: 365); // Annual rotation
    
    return iterations < recommendedIterations ||
           DateTime.now().difference(createdAt) > maxAge;
  }
  
  /// Secure comparison of hash values (constant-time)
  bool constantTimeEquals(Uint8List other) {
    if (hash.length != other.length) {
      return false;
    }
    
    int result = 0;
    for (int i = 0; i < hash.length; i++) {
      result |= hash[i] ^ other[i];
    }
    
    return result == 0;
  }
  
  /// Create a copy with updated iterations (for hash upgrades)
  PinHash copyWithIterations(int newIterations) {
    return PinHash.create(
      hash: hash,
      salt: salt,
      iterations: newIterations,
      algorithm: algorithm,
      createdAt: createdAt,
    );
  }
  
  /// Secure disposal of sensitive data
  void dispose() {
    // Overwrite sensitive arrays with zeros
    // Note: Dart doesn't guarantee memory clearing, but we attempt it
    hash.fillRange(0, hash.length, 0);
    salt.fillRange(0, salt.length, 0);
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PinHash &&
           constantTimeEquals(other.hash) &&
           _listEquals(salt, other.salt) &&
           iterations == other.iterations &&
           algorithm == other.algorithm &&
           createdAt == other.createdAt;
  }
  
  @override
  int get hashCode {
    // Don't include sensitive hash in hashCode calculation
    return Object.hash(
      salt.length,
      iterations,
      algorithm,
      createdAt,
    );
  }
  
  @override
  String toString() {
    // Never expose sensitive data in toString
    return 'PinHash(algorithm: $algorithm, iterations: $iterations, '
           'saltLength: ${salt.length}, hashLength: ${hash.length}, '
           'created: $createdAt)';
  }
  
  /// Helper method for list equality comparison
  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}