/// PBKDF2 Cryptographic Provider Implementation
/// 
/// Implements IPinCryptoProvider using PBKDF2-HMAC-SHA256 for PIN hashing.
/// Provides secure salt generation and constant-time verification.
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../services/pin_service.dart';
import '../models/pin_hash.dart';
import '../../crypto/random/secure_random.dart';

/// PBKDF2-HMAC-SHA256 implementation for PIN security
/// Provides cryptographically secure PIN hashing and verification
class Pbkdf2CryptoProvider implements IPinCryptoProvider {
  /// Default salt length in bytes (256 bits)
  static const int defaultSaltLength = 32;
  
  /// Minimum PBKDF2 iterations (NIST recommendation)
  static const int minIterations = 100000;
  
  /// Default PBKDF2 iterations for new hashes
  static const int defaultIterations = 200000;
  
  /// Output hash length in bytes (256 bits)
  static const int hashLength = 32;
  
  /// Secure random generator instance
  final SecureRandom _secureRandom = SecureRandom.instance;
  
  @override
  Uint8List generateSalt({int length = defaultSaltLength}) {
    if (length <= 0) {
      throw ArgumentError('Salt length must be positive');
    }
    
    if (length < 16) {
      throw ArgumentError('Salt length must be at least 16 bytes');
    }
    
    return _secureRandom.nextBytes(length);
  }
  
  @override
  Future<Uint8List> hashPin({
    required String pin,
    required Uint8List salt,
    required int iterations,
  }) async {
    if (pin.isEmpty) {
      throw ArgumentError('PIN cannot be empty');
    }
    
    if (salt.isEmpty) {
      throw ArgumentError('Salt cannot be empty');
    }
    
    if (iterations < minIterations) {
      throw ArgumentError('Iterations must be at least $minIterations');
    }
    
    try {
      // Convert PIN to UTF-8 bytes
      Uint8List pinBytes = Uint8List.fromList(utf8.encode(pin));
      
      // Perform PBKDF2-HMAC-SHA256
      Uint8List hash = await _pbkdf2HmacSha256(
        password: pinBytes,
        salt: salt,
        iterations: iterations,
        keyLength: hashLength,
      );
      
      // Clear PIN bytes from memory
      secureClear(pinBytes);
      
      return hash;
      
    } catch (e) {
      throw Exception('Failed to hash PIN: $e');
    }
  }
  
  @override
  Future<bool> verifyPin({
    required String pin,
    required PinHash storedHash,
  }) async {
    if (pin.isEmpty) {
      return false;
    }
    
    try {
      // Hash the input PIN with stored parameters
      Uint8List inputHash = await hashPin(
        pin: pin,
        salt: storedHash.salt,
        iterations: storedHash.iterations,
      );
      
      // Constant-time comparison
      bool isValid = storedHash.constantTimeEquals(inputHash);
      
      // Clear input hash from memory
      secureClear(inputHash);
      
      return isValid;
      
    } catch (e) {
      // Authentication should fail on any error
      return false;
    }
  }
  
  @override
  Future<int> getRecommendedIterations() async {
    // Could implement device-specific calibration here
    // For now, return a secure default
    return defaultIterations;
  }
  
  @override
  void secureClear(Uint8List data) {
    // Dart doesn't guarantee memory clearing, but attempt to overwrite
    for (int i = 0; i < data.length; i++) {
      data[i] = 0;
    }
  }
  
  /// PBKDF2-HMAC-SHA256 implementation
  /// Returns derived key of specified length
  Future<Uint8List> _pbkdf2HmacSha256({
    required Uint8List password,
    required Uint8List salt,
    required int iterations,
    required int keyLength,
  }) async {
    if (keyLength <= 0) {
      throw ArgumentError('Key length must be positive');
    }
    
    const int hashLength = 32; // SHA-256 output length
    int blocks = (keyLength + hashLength - 1) ~/ hashLength;
    
    Uint8List derivedKey = Uint8List(keyLength);
    int offset = 0;
    
    for (int blockIndex = 1; blockIndex <= blocks; blockIndex++) {
      Uint8List block = await _pbkdf2Block(
        password: password,
        salt: salt,
        iterations: iterations,
        blockIndex: blockIndex,
      );
      
      int copyLength = keyLength - offset;
      if (copyLength > hashLength) {
        copyLength = hashLength;
      }
      
      derivedKey.setRange(offset, offset + copyLength, block);
      offset += copyLength;
      
      // Clear block from memory
      secureClear(block);
    }
    
    return derivedKey;
  }
  
  /// Compute a single PBKDF2 block
  Future<Uint8List> _pbkdf2Block({
    required Uint8List password,
    required Uint8List salt,
    required int iterations,
    required int blockIndex,
  }) async {
    // Create HMAC-SHA256 instance
    Hmac hmac = Hmac(sha256, password);
    
    // Initial salt + block index (big-endian)
    Uint8List saltAndIndex = Uint8List(salt.length + 4);
    saltAndIndex.setRange(0, salt.length, salt);
    saltAndIndex[salt.length] = (blockIndex >> 24) & 0xFF;
    saltAndIndex[salt.length + 1] = (blockIndex >> 16) & 0xFF;
    saltAndIndex[salt.length + 2] = (blockIndex >> 8) & 0xFF;
    saltAndIndex[salt.length + 3] = blockIndex & 0xFF;
    
    // U1 = HMAC(password, salt || blockIndex)
    Digest u = hmac.convert(saltAndIndex);
    Uint8List result = Uint8List.fromList(u.bytes);
    Uint8List currentU = Uint8List.fromList(u.bytes);
    
    // Un = HMAC(password, Un-1) for iterations - 1
    for (int i = 1; i < iterations; i++) {
      Digest nextU = hmac.convert(currentU);
      currentU = Uint8List.fromList(nextU.bytes);
      
      // XOR with result
      for (int j = 0; j < result.length; j++) {
        result[j] ^= currentU[j];
      }
    }
    
    // Clear intermediate values
    secureClear(saltAndIndex);
    secureClear(currentU);
    
    return result;
  }
  
  /// Benchmark PBKDF2 performance for iteration calibration
  Future<Map<String, int>> benchmarkPerformance() async {
    const String testPin = "test123";
    const int testIterations = 10000;
    
    Uint8List salt = generateSalt();
    
    Stopwatch stopwatch = Stopwatch()..start();
    
    await hashPin(
      pin: testPin,
      salt: salt,
      iterations: testIterations,
    );
    
    stopwatch.stop();
    
    double microsecondsPerIteration = 
        stopwatch.elapsedMicroseconds / testIterations;
    
    // Calculate iterations for target timing
    const int targetMilliseconds = 500; // 0.5 second target
    int recommendedIterations = 
        (targetMilliseconds * 1000 / microsecondsPerIteration).round();
    
    // Ensure minimum security
    if (recommendedIterations < minIterations) {
      recommendedIterations = minIterations;
    }
    
    // Clean up
    secureClear(salt);
    
    return {
      'testIterations': testIterations,
      'elapsedMicroseconds': stopwatch.elapsedMicroseconds,
      'microsecondsPerIteration': microsecondsPerIteration.round(),
      'recommendedIterations': recommendedIterations,
      'targetMilliseconds': targetMilliseconds,
    };
  }
}