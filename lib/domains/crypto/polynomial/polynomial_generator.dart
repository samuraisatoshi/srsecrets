/// Polynomial Generation for Shamir's Secret Sharing
/// 
/// This module handles the generation of random polynomials used in
/// Shamir's Secret Sharing scheme. The polynomial's constant term is
/// the secret, and the other coefficients are randomly generated.
library;

import 'dart:typed_data';
import '../finite_field/gf256.dart';
import '../random/secure_random.dart';

/// Generates polynomials for Shamir's Secret Sharing
class PolynomialGenerator {
  /// Random number generator for coefficients
  static final SecureRandom _random = SecureRandom.instance;
  
  /// Generate a random polynomial with given secret and degree
  /// 
  /// The polynomial has the form:
  /// f(x) = secret + a₁x + a₂x² + ... + aₙxⁿ
  /// 
  /// Parameters:
  /// - [secret]: The secret value (constant term of polynomial)
  /// - [threshold]: The minimum number of shares needed to reconstruct
  /// - [fieldSize]: The size of the finite field (default 256 for GF(2^8))
  /// 
  /// Returns: List of coefficients [secret, a₁, a₂, ..., aₙ]
  static List<int> generatePolynomial({
    required int secret,
    required int threshold,
    int fieldSize = 256,
  }) {
    if (threshold < 2) {
      throw ArgumentError('Threshold must be at least 2');
    }
    
    if (threshold > fieldSize) {
      throw ArgumentError(
        'Threshold cannot exceed field size ($fieldSize)'
      );
    }
    
    if (!GF256.isValidElement(secret)) {
      throw ArgumentError(
        'Secret must be a valid GF(256) element (0-255)'
      );
    }
    
    // Polynomial degree is threshold - 1
    int degree = threshold - 1;
    
    // Generate coefficients: [secret, a₁, a₂, ..., aₙ]
    List<int> coefficients = List<int>.filled(degree + 1, 0);
    
    // Set the constant term to the secret
    coefficients[0] = secret;
    
    // Generate random coefficients for higher degree terms
    // These must be non-zero to ensure the polynomial has the expected degree
    for (int i = 1; i <= degree; i++) {
      if (i == degree) {
        // The highest degree coefficient must be non-zero
        // to ensure the polynomial has exactly the required degree
        coefficients[i] = _random.nextNonZeroGF256Element();
      } else {
        // Other coefficients can be any value in the field
        coefficients[i] = _random.nextGF256Element();
      }
    }
    
    return coefficients;
  }
  
  /// Generate multiple independent polynomials for sharing multiple secrets
  /// 
  /// This is useful when sharing multiple bytes of a larger secret
  /// Each polynomial is independent with its own random coefficients
  static List<List<int>> generateMultiplePolynomials({
    required List<int> secrets,
    required int threshold,
    int fieldSize = 256,
  }) {
    if (secrets.isEmpty) {
      throw ArgumentError('Secrets list cannot be empty');
    }
    
    List<List<int>> polynomials = [];
    
    for (int secret in secrets) {
      polynomials.add(
        generatePolynomial(
          secret: secret,
          threshold: threshold,
          fieldSize: fieldSize,
        ),
      );
    }
    
    return polynomials;
  }
  
  /// Generate polynomial coefficients for a byte array secret
  /// 
  /// Splits a byte array into individual bytes and generates
  /// a polynomial for each byte independently
  static List<List<int>> generateForByteArray({
    required Uint8List secretBytes,
    required int threshold,
  }) {
    if (secretBytes.isEmpty) {
      throw ArgumentError('Secret bytes cannot be empty');
    }
    
    return generateMultiplePolynomials(
      secrets: secretBytes.toList(),
      threshold: threshold,
    );
  }
  
  /// Evaluate a polynomial at a given x value in GF(256)
  /// 
  /// Uses Horner's method for efficient evaluation
  static int evaluatePolynomial(List<int> coefficients, int x) {
    if (!GF256.isValidElement(x)) {
      throw ArgumentError('x must be a valid GF(256) element (0-255)');
    }
    
    return GF256.evaluatePolynomial(coefficients, x);
  }
  
  /// Generate evaluation points (x values) for creating shares
  /// 
  /// Returns n unique non-zero x values for share generation
  /// x=0 is reserved for the secret itself
  static List<int> generateEvaluationPoints(int n) {
    if (n < 1) {
      throw ArgumentError('Number of points must be at least 1');
    }
    
    if (n > 255) {
      throw ArgumentError(
        'Cannot generate more than 255 points in GF(256)'
      );
    }
    
    // Method 1: Sequential (deterministic, simple)
    // return List<int>.generate(n, (i) => i + 1);
    
    // Method 2: Random selection (more secure)
    Set<int> points = {};
    while (points.length < n) {
      int point = _random.nextNonZeroGF256Element();
      points.add(point);
    }
    
    return points.toList()..sort();
  }
  
  /// Validate polynomial coefficients
  static bool validatePolynomial(List<int> coefficients) {
    if (coefficients.isEmpty) {
      return false;
    }
    
    // Check all coefficients are valid field elements
    for (int coeff in coefficients) {
      if (!GF256.isValidElement(coeff)) {
        return false;
      }
    }
    
    // Check that the highest degree coefficient is non-zero
    // (except for constant polynomial)
    if (coefficients.length > 1) {
      return coefficients.last != 0;
    }
    
    return true;
  }
  
  /// Calculate the degree of a polynomial
  /// 
  /// Returns the actual degree (ignoring trailing zero coefficients)
  static int polynomialDegree(List<int> coefficients) {
    if (coefficients.isEmpty) {
      return -1; // Undefined for empty polynomial
    }
    
    // Find the highest non-zero coefficient
    for (int i = coefficients.length - 1; i >= 0; i--) {
      if (coefficients[i] != 0) {
        return i;
      }
    }
    
    return 0; // Constant polynomial (possibly zero)
  }
  
  /// Generate a test polynomial with known coefficients
  /// 
  /// Useful for testing and debugging
  static List<int> generateTestPolynomial({
    required int secret,
    required int threshold,
    List<int>? fixedCoefficients,
  }) {
    int degree = threshold - 1;
    List<int> coefficients = List<int>.filled(degree + 1, 0);
    
    coefficients[0] = secret;
    
    if (fixedCoefficients != null) {
      // Use provided coefficients for testing
      for (int i = 1; i <= degree && i <= fixedCoefficients.length; i++) {
        coefficients[i] = fixedCoefficients[i - 1];
      }
      // Ensure highest coefficient is non-zero
      if (coefficients[degree] == 0) {
        coefficients[degree] = 1;
      }
    } else {
      // Use simple sequential coefficients for testing
      for (int i = 1; i <= degree; i++) {
        coefficients[i] = i;
      }
    }
    
    return coefficients;
  }
}