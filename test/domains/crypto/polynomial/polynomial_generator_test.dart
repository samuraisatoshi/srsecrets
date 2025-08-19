import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/domains/crypto/polynomial/polynomial_generator.dart';
import 'package:srsecrets/domains/crypto/finite_field/gf256.dart';
import 'dart:typed_data';

void main() {
  group('PolynomialGenerator', () {
    
    group('Basic Polynomial Generation', () {
      test('should generate polynomial with correct structure', () {
        const secret = 42;
        const threshold = 3;
        
        final coefficients = PolynomialGenerator.generatePolynomial(
          secret: secret,
          threshold: threshold,
        );
        
        expect(coefficients.length, equals(threshold));
        expect(coefficients[0], equals(secret)); // Constant term is secret
        
        // Highest degree coefficient should be non-zero
        expect(coefficients[threshold - 1], isNot(equals(0)));
        
        // All coefficients should be valid GF256 elements
        for (final coeff in coefficients) {
          expect(GF256.isValidElement(coeff), isTrue);
        }
      });
      
      test('should generate different polynomials each time', () {
        const secret = 100;
        const threshold = 4;
        
        final poly1 = PolynomialGenerator.generatePolynomial(
          secret: secret,
          threshold: threshold,
        );
        
        final poly2 = PolynomialGenerator.generatePolynomial(
          secret: secret,
          threshold: threshold,
        );
        
        // Constant terms should be the same (secret)
        expect(poly1[0], equals(poly2[0]));
        
        // Other coefficients should likely be different
        // (probability of identical is extremely low)
        bool hasDifference = false;
        for (int i = 1; i < threshold; i++) {
          if (poly1[i] != poly2[i]) {
            hasDifference = true;
            break;
          }
        }
        expect(hasDifference, isTrue);
      });
      
      test('should handle minimum threshold of 2', () {
        const secret = 200;
        const threshold = 2;
        
        final coefficients = PolynomialGenerator.generatePolynomial(
          secret: secret,
          threshold: threshold,
        );
        
        expect(coefficients.length, equals(2));
        expect(coefficients[0], equals(secret));
        expect(coefficients[1], isNot(equals(0))); // Linear coefficient non-zero
      });
      
      test('should handle maximum practical threshold', () {
        const secret = 77;
        const threshold = 255; // Maximum for GF256
        
        final coefficients = PolynomialGenerator.generatePolynomial(
          secret: secret,
          threshold: threshold,
        );
        
        expect(coefficients.length, equals(threshold));
        expect(coefficients[0], equals(secret));
        expect(coefficients[threshold - 1], isNot(equals(0)));
      });
      
      test('should throw for invalid threshold', () {
        const secret = 50;
        
        // Threshold too small
        expect(
          () => PolynomialGenerator.generatePolynomial(
            secret: secret,
            threshold: 1,
          ),
          throwsArgumentError,
        );
        
        expect(
          () => PolynomialGenerator.generatePolynomial(
            secret: secret,
            threshold: 0,
          ),
          throwsArgumentError,
        );
        
        // Threshold too large
        expect(
          () => PolynomialGenerator.generatePolynomial(
            secret: secret,
            threshold: 257,
          ),
          throwsArgumentError,
        );
      });
      
      test('should throw for invalid secret', () {
        const threshold = 3;
        
        // Secret out of GF256 range
        expect(
          () => PolynomialGenerator.generatePolynomial(
            secret: -1,
            threshold: threshold,
          ),
          throwsArgumentError,
        );
        
        expect(
          () => PolynomialGenerator.generatePolynomial(
            secret: 256,
            threshold: threshold,
          ),
          throwsArgumentError,
        );
      });
    });
    
    group('Multiple Polynomial Generation', () {
      test('should generate independent polynomials for multiple secrets', () {
        final secrets = [10, 20, 30, 40];
        const threshold = 3;
        
        final polynomials = PolynomialGenerator.generateMultiplePolynomials(
          secrets: secrets,
          threshold: threshold,
        );
        
        expect(polynomials.length, equals(secrets.length));
        
        for (int i = 0; i < secrets.length; i++) {
          final poly = polynomials[i];
          expect(poly.length, equals(threshold));
          expect(poly[0], equals(secrets[i])); // Correct secret
          expect(poly[threshold - 1], isNot(equals(0))); // Non-zero high coeff
        }
      });
      
      test('should throw for empty secrets list', () {
        expect(
          () => PolynomialGenerator.generateMultiplePolynomials(
            secrets: [],
            threshold: 3,
          ),
          throwsArgumentError,
        );
      });
      
      test('should handle single secret in list', () {
        final secrets = [123];
        const threshold = 4;
        
        final polynomials = PolynomialGenerator.generateMultiplePolynomials(
          secrets: secrets,
          threshold: threshold,
        );
        
        expect(polynomials.length, equals(1));
        expect(polynomials[0][0], equals(123));
        expect(polynomials[0].length, equals(threshold));
      });
    });
    
    group('Byte Array Polynomial Generation', () {
      test('should generate polynomials for byte array', () {
        final secretBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        const threshold = 3;
        
        final polynomials = PolynomialGenerator.generateForByteArray(
          secretBytes: secretBytes,
          threshold: threshold,
        );
        
        expect(polynomials.length, equals(secretBytes.length));
        
        for (int i = 0; i < secretBytes.length; i++) {
          expect(polynomials[i][0], equals(secretBytes[i]));
          expect(polynomials[i].length, equals(threshold));
        }
      });
      
      test('should throw for empty byte array', () {
        final emptyBytes = Uint8List(0);
        
        expect(
          () => PolynomialGenerator.generateForByteArray(
            secretBytes: emptyBytes,
            threshold: 3,
          ),
          throwsArgumentError,
        );
      });
      
      test('should handle single byte array', () {
        final singleByte = Uint8List.fromList([255]);
        const threshold = 2;
        
        final polynomials = PolynomialGenerator.generateForByteArray(
          secretBytes: singleByte,
          threshold: threshold,
        );
        
        expect(polynomials.length, equals(1));
        expect(polynomials[0][0], equals(255));
      });
    });
    
    group('Polynomial Evaluation', () {
      test('should evaluate polynomial correctly', () {
        // Test with known polynomial: f(x) = 7 + 3x + 2x^2
        final coefficients = [7, 3, 2];
        
        // f(0) = 7
        expect(PolynomialGenerator.evaluatePolynomial(coefficients, 0), equals(7));
        
        // f(1) = 7 + 3 + 2 = 12 (in GF256: 7 ^ 3 ^ 2 = 6)
        final expected1 = GF256.add(GF256.add(7, 3), 2);
        expect(PolynomialGenerator.evaluatePolynomial(coefficients, 1), equals(expected1));
        
        // Test at x = 5
        final term1 = 7;
        final term2 = GF256.multiply(3, 5);
        final term3 = GF256.multiply(2, GF256.power(5, 2));
        final expected5 = GF256.add(GF256.add(term1, term2), term3);
        expect(PolynomialGenerator.evaluatePolynomial(coefficients, 5), equals(expected5));
      });
      
      test('should handle constant polynomial', () {
        final constantPoly = [42];
        
        // Should return constant for any x
        for (int x = 0; x < 10; x++) {
          expect(PolynomialGenerator.evaluatePolynomial(constantPoly, x), equals(42));
        }
      });
      
      test('should throw for invalid x value', () {
        final coefficients = [1, 2, 3];
        
        expect(
          () => PolynomialGenerator.evaluatePolynomial(coefficients, -1),
          throwsArgumentError,
        );
        
        expect(
          () => PolynomialGenerator.evaluatePolynomial(coefficients, 256),
          throwsArgumentError,
        );
      });
    });
    
    group('Evaluation Points Generation', () {
      test('should generate correct number of points', () {
        for (int n = 1; n <= 10; n++) {
          final points = PolynomialGenerator.generateEvaluationPoints(n);
          expect(points.length, equals(n));
        }
      });
      
      test('should generate unique non-zero points', () {
        const n = 50;
        final points = PolynomialGenerator.generateEvaluationPoints(n);
        
        // All points should be unique
        expect(points.toSet().length, equals(n));
        
        // No point should be zero
        expect(points.contains(0), isFalse);
        
        // All points should be valid GF256 elements
        for (final point in points) {
          expect(point, greaterThan(0));
          expect(point, lessThanOrEqualTo(255));
        }
      });
      
      test('should return sorted points', () {
        const n = 20;
        final points = PolynomialGenerator.generateEvaluationPoints(n);
        final sortedPoints = [...points]..sort();
        
        expect(points, equals(sortedPoints));
      });
      
      test('should throw for invalid n', () {
        expect(
          () => PolynomialGenerator.generateEvaluationPoints(0),
          throwsArgumentError,
        );
        
        expect(
          () => PolynomialGenerator.generateEvaluationPoints(-1),
          throwsArgumentError,
        );
        
        expect(
          () => PolynomialGenerator.generateEvaluationPoints(256),
          throwsArgumentError,
        );
      });
      
      test('should handle maximum possible points', () {
        const n = 255; // Maximum non-zero elements in GF256
        final points = PolynomialGenerator.generateEvaluationPoints(n);
        
        expect(points.length, equals(n));
        expect(points.toSet().length, equals(n)); // All unique
        expect(points.contains(0), isFalse);
      });
    });
    
    group('Polynomial Validation', () {
      test('should validate correct polynomials', () {
        // Valid polynomial
        final validPoly = [42, 13, 7];
        expect(PolynomialGenerator.validatePolynomial(validPoly), isTrue);
        
        // Valid constant polynomial
        final constantPoly = [100];
        expect(PolynomialGenerator.validatePolynomial(constantPoly), isTrue);
        
        // Valid polynomial with zero middle coefficient
        final polyWithZero = [50, 0, 15];
        expect(PolynomialGenerator.validatePolynomial(polyWithZero), isTrue);
      });
      
      test('should reject invalid polynomials', () {
        // Empty polynomial
        expect(PolynomialGenerator.validatePolynomial([]), isFalse);
        
        // Polynomial with invalid coefficient
        final invalidCoeff = [42, 256, 7];
        expect(PolynomialGenerator.validatePolynomial(invalidCoeff), isFalse);
        
        final negativeCoeff = [42, -1, 7];
        expect(PolynomialGenerator.validatePolynomial(negativeCoeff), isFalse);
        
        // Polynomial with zero highest coefficient (invalid degree)
        final zeroHighCoeff = [42, 13, 0];
        expect(PolynomialGenerator.validatePolynomial(zeroHighCoeff), isFalse);
      });
    });
    
    group('Polynomial Degree Calculation', () {
      test('should calculate correct degree', () {
        expect(PolynomialGenerator.polynomialDegree([42]), equals(0)); // Constant
        expect(PolynomialGenerator.polynomialDegree([0]), equals(0)); // Zero constant
        expect(PolynomialGenerator.polynomialDegree([42, 13]), equals(1)); // Linear
        expect(PolynomialGenerator.polynomialDegree([42, 13, 7]), equals(2)); // Quadratic
        
        // Polynomial with trailing zeros (should ignore them)
        expect(PolynomialGenerator.polynomialDegree([42, 13, 0, 0]), equals(1));
      });
      
      test('should handle edge cases', () {
        // Empty polynomial
        expect(PolynomialGenerator.polynomialDegree([]), equals(-1));
        
        // All zero polynomial
        expect(PolynomialGenerator.polynomialDegree([0, 0, 0]), equals(0));
      });
    });
    
    group('Test Polynomial Generation', () {
      test('should generate test polynomial with known coefficients', () {
        const secret = 123;
        const threshold = 4;
        final fixedCoeffs = [10, 20, 30];
        
        final testPoly = PolynomialGenerator.generateTestPolynomial(
          secret: secret,
          threshold: threshold,
          fixedCoefficients: fixedCoeffs,
        );
        
        expect(testPoly.length, equals(threshold));
        expect(testPoly[0], equals(secret));
        expect(testPoly[1], equals(10));
        expect(testPoly[2], equals(20));
        expect(testPoly[3], equals(30));
      });
      
      test('should ensure non-zero highest coefficient in test polynomial', () {
        const secret = 50;
        const threshold = 3;
        final zeroHighCoeff = [10, 0]; // Would make highest coeff zero
        
        final testPoly = PolynomialGenerator.generateTestPolynomial(
          secret: secret,
          threshold: threshold,
          fixedCoefficients: zeroHighCoeff,
        );
        
        expect(testPoly[threshold - 1], isNot(equals(0))); // Should be fixed to 1
        expect(testPoly[threshold - 1], equals(1));
      });
      
      test('should generate sequential coefficients when no fixed coefficients', () {
        const secret = 77;
        const threshold = 5;
        
        final testPoly = PolynomialGenerator.generateTestPolynomial(
          secret: secret,
          threshold: threshold,
        );
        
        expect(testPoly[0], equals(secret));
        expect(testPoly[1], equals(1));
        expect(testPoly[2], equals(2));
        expect(testPoly[3], equals(3));
        expect(testPoly[4], equals(4));
      });
      
      test('should handle partial fixed coefficients', () {
        const secret = 200;
        const threshold = 4;
        final partialCoeffs = [99]; // Only one fixed coefficient
        
        final testPoly = PolynomialGenerator.generateTestPolynomial(
          secret: secret,
          threshold: threshold,
          fixedCoefficients: partialCoeffs,
        );
        
        expect(testPoly[0], equals(secret));
        expect(testPoly[1], equals(99)); // From fixed coefficients
        expect(testPoly[2], equals(2));  // Default sequential
        expect(testPoly[3], equals(3));  // Default sequential
      });
    });
    
    group('Integration Tests', () {
      test('generated polynomial should work with GF256 evaluation', () {
        const secret = 155;
        const threshold = 3;
        
        final coefficients = PolynomialGenerator.generatePolynomial(
          secret: secret,
          threshold: threshold,
        );
        
        // Evaluate at x=0 should give secret
        final evaluated = GF256.evaluatePolynomial(coefficients, 0);
        expect(evaluated, equals(secret));
        
        // Evaluate at other points should give consistent results
        final x1 = 1, x2 = 2;
        final y1 = GF256.evaluatePolynomial(coefficients, x1);
        final y2 = GF256.evaluatePolynomial(coefficients, x2);
        
        // Lagrange interpolation with threshold points should recover secret
        final xValues = [0, x1, x2];
        final yValues = [secret, y1, y2];
        final reconstructed = GF256.lagrangeInterpolate(xValues, yValues);
        expect(reconstructed, equals(secret));
      });
      
      test('polynomial evaluation should be consistent with direct GF256', () {
        final coefficients = [7, 3, 2]; // f(x) = 7 + 3x + 2x^2
        const x = 10;
        
        // Using PolynomialGenerator
        final result1 = PolynomialGenerator.evaluatePolynomial(coefficients, x);
        
        // Using GF256 directly
        final result2 = GF256.evaluatePolynomial(coefficients, x);
        
        expect(result1, equals(result2));
      });
    });
  });
}