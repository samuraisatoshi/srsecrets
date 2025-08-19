/// Cryptographically Secure Random Number Generation
/// 
/// Provides secure random number generation for cryptographic operations
/// using Dart's Random.secure() and additional entropy mixing.
library;

import 'dart:math';
import 'dart:typed_data';

/// Secure random number generator for cryptographic operations
class SecureRandom {
  /// The underlying secure random generator
  late final Random _random;
  
  /// Entropy pool for additional randomness
  final Uint8List _entropyPool = Uint8List(256);
  
  /// Current position in entropy pool
  int _entropyPosition = 0;
  
  /// Singleton instance
  static SecureRandom? _instance;
  
  /// Private constructor
  SecureRandom._() {
    _random = Random.secure();
    _initializeEntropyPool();
  }
  
  /// Get singleton instance
  static SecureRandom get instance {
    _instance ??= SecureRandom._();
    return _instance!;
  }
  
  /// Initialize entropy pool with secure random data
  void _initializeEntropyPool() {
    for (int i = 0; i < _entropyPool.length; i++) {
      _entropyPool[i] = _random.nextInt(256);
    }
  }
  
  /// Mix additional entropy into the pool
  void _mixEntropy() {
    // Simple entropy mixing using XOR and rotation
    int carry = _entropyPool[_entropyPool.length - 1];
    for (int i = _entropyPool.length - 1; i > 0; i--) {
      _entropyPool[i] = _entropyPool[i] ^ _entropyPool[i - 1] ^ carry;
      carry = _entropyPool[i];
    }
    _entropyPool[0] = _entropyPool[0] ^ carry;
    
    // Add fresh entropy
    int freshByte = _random.nextInt(256);
    _entropyPool[_entropyPosition] ^= freshByte;
    _entropyPosition = (_entropyPosition + 1) % _entropyPool.length;
  }
  
  /// Generate a secure random byte (0-255)
  int nextByte() {
    _mixEntropy();
    return _random.nextInt(256) ^ _entropyPool[_entropyPosition];
  }
  
  /// Generate a secure random integer in range [0, max)
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError('max must be positive');
    }
    
    if (max <= 256) {
      // For small values, use rejection sampling for uniform distribution
      int limit = 256 - (256 % max);
      int value;
      do {
        value = nextByte();
      } while (value >= limit);
      return value % max;
    }
    
    // For larger values, use the secure random directly
    _mixEntropy();
    return _random.nextInt(max);
  }
  
  /// Generate secure random bytes
  Uint8List nextBytes(int length) {
    if (length <= 0) {
      throw ArgumentError('length must be positive');
    }
    
    Uint8List result = Uint8List(length);
    for (int i = 0; i < length; i++) {
      result[i] = nextByte();
    }
    return result;
  }
  
  /// Generate a secure random BigInt with specified number of bits
  BigInt nextBigInt(int bitLength) {
    if (bitLength <= 0) {
      throw ArgumentError('bitLength must be positive');
    }
    
    int byteLength = (bitLength + 7) ~/ 8;
    Uint8List bytes = nextBytes(byteLength);
    
    // Mask off excess bits in the last byte
    int excessBits = (byteLength * 8) - bitLength;
    if (excessBits > 0) {
      bytes[0] &= (1 << (8 - excessBits)) - 1;
    }
    
    // Convert bytes to BigInt
    BigInt result = BigInt.zero;
    for (int byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    
    return result;
  }
  
  /// Generate a secure random double in range [0.0, 1.0)
  double nextDouble() {
    // Use 53 bits of precision (IEEE 754 double precision)
    const int precision = 53;
    BigInt randomBits = nextBigInt(precision);
    BigInt maxValue = BigInt.one << precision;
    return randomBits.toDouble() / maxValue.toDouble();
  }
  
  /// Generate a secure random boolean
  bool nextBool() {
    return nextByte() >= 128;
  }
  
  /// Generate a list of unique random integers in range [0, max)
  List<int> uniqueIntegers(int count, int max) {
    if (count > max) {
      throw ArgumentError('Cannot generate more unique values than max');
    }
    
    Set<int> result = {};
    while (result.length < count) {
      result.add(nextInt(max));
    }
    
    return result.toList()..sort();
  }
  
  /// Shuffle a list securely in place using Fisher-Yates algorithm
  void shuffle<T>(List<T> list) {
    for (int i = list.length - 1; i > 0; i--) {
      int j = nextInt(i + 1);
      T temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }
  
  /// Generate a secure random element from GF(2^8)
  int nextGF256Element() {
    return nextByte();
  }
  
  /// Generate a list of secure random GF(2^8) elements
  List<int> nextGF256Elements(int count) {
    List<int> result = [];
    for (int i = 0; i < count; i++) {
      result.add(nextGF256Element());
    }
    return result;
  }
  
  /// Generate non-zero GF(2^8) element
  int nextNonZeroGF256Element() {
    int value;
    do {
      value = nextByte();
    } while (value == 0);
    return value;
  }
  
  /// Clear entropy pool (security cleanup)
  void secureClear() {
    _entropyPool.fillRange(0, _entropyPool.length, 0);
    _entropyPosition = 0;
    // Note: Cannot clear the underlying Random.secure() instance
  }
  
  /// Reseed the entropy pool with fresh randomness
  void reseed() {
    _initializeEntropyPool();
    _entropyPosition = 0;
  }
}