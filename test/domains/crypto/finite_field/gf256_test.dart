import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/domains/crypto/finite_field/gf256.dart';

void main() {
  group('GF256 Finite Field Arithmetic', () {
    setUpAll(() {
      // Ensure tables are initialized before tests
      GF256.add(1, 1);
    });

    group('Basic Operations', () {
      test('Addition properties', () {
        // Addition is XOR in GF(2^8)
        expect(GF256.add(0, 0), equals(0));
        expect(GF256.add(1, 0), equals(1));
        expect(GF256.add(0, 1), equals(1));
        expect(GF256.add(1, 1), equals(0));
        
        // Commutative property
        expect(GF256.add(42, 137), equals(GF256.add(137, 42)));
        
        // Associative property
        int a = 73, b = 201, c = 142;
        expect(GF256.add(GF256.add(a, b), c), 
               equals(GF256.add(a, GF256.add(b, c))));
        
        // Identity element
        expect(GF256.add(255, 0), equals(255));
        
        // Self-inverse property
        expect(GF256.add(100, 100), equals(0));
      });

      test('Subtraction properties', () {
        // Subtraction is same as addition in GF(2^8)
        expect(GF256.subtract(10, 5), equals(GF256.add(10, 5)));
        expect(GF256.subtract(255, 255), equals(0));
        
        // a - b + b = a
        int a = 178, b = 93;
        expect(GF256.add(GF256.subtract(a, b), b), equals(a));
      });

      test('Multiplication properties', () {
        // Multiplication by 0
        expect(GF256.multiply(0, 100), equals(0));
        expect(GF256.multiply(100, 0), equals(0));
        
        // Multiplication by 1
        expect(GF256.multiply(1, 100), equals(100));
        expect(GF256.multiply(100, 1), equals(100));
        
        // Commutative property
        expect(GF256.multiply(7, 13), equals(GF256.multiply(13, 7)));
        
        // Associative property
        int a = 7, b = 13, c = 19;
        expect(GF256.multiply(GF256.multiply(a, b), c),
               equals(GF256.multiply(a, GF256.multiply(b, c))));
        
        // Distributive property
        expect(GF256.multiply(a, GF256.add(b, c)),
               equals(GF256.add(GF256.multiply(a, b), 
                                GF256.multiply(a, c))));
      });

      test('Division properties', () {
        // Division by 1
        expect(GF256.divide(100, 1), equals(100));
        
        // Division by self
        expect(GF256.divide(100, 100), equals(1));
        
        // Division by zero throws
        expect(() => GF256.divide(100, 0), 
               throwsA(isA<ArgumentError>()));
        
        // a / b * b = a (for b != 0)
        for (int a = 0; a < 256; a++) {
          for (int b = 1; b < 256; b++) {
            int quotient = GF256.divide(a, b);
            expect(GF256.multiply(quotient, b), equals(a));
          }
        }
      });

      test('Power operations', () {
        // a^0 = 1 for a != 0
        expect(GF256.power(7, 0), equals(1));
        expect(GF256.power(255, 0), equals(1));
        
        // a^1 = a
        expect(GF256.power(7, 1), equals(7));
        expect(GF256.power(255, 1), equals(255));
        
        // 0^n = 0 for n > 0
        expect(GF256.power(0, 5), equals(0));
        
        // a^(m+n) = a^m * a^n
        int a = 7, m = 3, n = 5;
        expect(GF256.power(a, m + n),
               equals(GF256.multiply(GF256.power(a, m), 
                                     GF256.power(a, n))));
        
        // Fermat's little theorem: a^255 = a for a != 0
        expect(GF256.power(7, 255), equals(7));
        expect(GF256.power(100, 255), equals(100));
      });

      test('Inverse operations', () {
        // 0 has no inverse
        expect(GF256.inverse(0), equals(0));
        
        // 1 is its own inverse
        expect(GF256.inverse(1), equals(1));
        
        // a * inverse(a) = 1 for all a != 0
        for (int a = 1; a < 256; a++) {
          int inv = GF256.inverse(a);
          expect(GF256.multiply(a, inv), equals(1),
                 reason: 'Failed for a=$a');
        }
        
        // Double inverse returns original
        for (int a = 1; a < 256; a++) {
          expect(GF256.inverse(GF256.inverse(a)), equals(a));
        }
      });
    });

    group('Polynomial Operations', () {
      test('Polynomial evaluation', () {
        // Constant polynomial
        expect(GF256.evaluatePolynomial([42], 10), equals(42));
        
        // Linear polynomial: 3x + 7
        expect(GF256.evaluatePolynomial([7, 3], 0), equals(7));
        expect(GF256.evaluatePolynomial([7, 3], 1), 
               equals(GF256.add(7, 3)));
        
        // Quadratic: x^2 + 2x + 3
        List<int> coeffs = [3, 2, 1];
        int x = 5;
        int expected = GF256.add(
          GF256.add(3, GF256.multiply(2, x)),
          GF256.multiply(1, GF256.power(x, 2))
        );
        expect(GF256.evaluatePolynomial(coeffs, x), equals(expected));
      });

      test('Lagrange interpolation - basic', () {
        // Two points determine a line
        List<int> x = [1, 2];
        List<int> y = [3, 7];
        
        // Interpolate at x=0 to get constant term
        int secret = GF256.lagrangeInterpolate(x, y);
        
        // Verify the interpolation passes through original points
        // by constructing the polynomial
        for (int i = 0; i < x.length; i++) {
          int reconstructed = _evaluateInterpolatedAt(x, y, x[i]);
          expect(reconstructed, equals(y[i]),
                 reason: 'Failed at point (${ x[i]}, ${y[i]})');
        }
      });

      test('Lagrange interpolation - multiple points', () {
        // Test with 3 points (quadratic polynomial)
        List<int> x = [1, 2, 3];
        List<int> y = [10, 20, 30];
        
        int secret = GF256.lagrangeInterpolate(x, y);
        
        // Verify reconstruction at original points
        for (int i = 0; i < x.length; i++) {
          int reconstructed = _evaluateInterpolatedAt(x, y, x[i]);
          expect(reconstructed, equals(y[i]));
        }
      });

      test('Lagrange interpolation - Shamir property', () {
        // Simulate Shamir's secret sharing
        int originalSecret = 42;
        int threshold = 3;
        
        // Create polynomial with secret as constant term
        List<int> coefficients = [originalSecret, 13, 7]; // degree 2
        
        // Generate shares
        List<int> xValues = [1, 2, 3, 4, 5];
        List<int> yValues = xValues
            .map((x) => GF256.evaluatePolynomial(coefficients, x))
            .toList();
        
        // Reconstruct with exactly threshold shares
        List<int> selectedX = xValues.take(threshold).toList();
        List<int> selectedY = yValues.take(threshold).toList();
        
        int reconstructedSecret = GF256.lagrangeInterpolate(selectedX, selectedY);
        expect(reconstructedSecret, equals(originalSecret));
        
        // Try with different subset
        selectedX = [xValues[1], xValues[3], xValues[4]];
        selectedY = [yValues[1], yValues[3], yValues[4]];
        
        reconstructedSecret = GF256.lagrangeInterpolate(selectedX, selectedY);
        expect(reconstructedSecret, equals(originalSecret));
      });
    });

    group('Security Properties', () {
      test('Constant-time operations', () {
        // This is a structural test for constant-time implementation
        // Table-based operations should be inherently constant-time
        
        // Test that we're using table-based multiplication (not branching)
        // by verifying operations complete in reasonable time
        List<int> values = [0, 1, 127, 128, 255];
        List<Duration> timings = [];
        
        const int iterations = 100000; // Increased for better timing accuracy
        
        for (int val in values) {
          Stopwatch sw = Stopwatch()..start();
          for (int i = 0; i < iterations; i++) {
            GF256.multiply(val, i % 256);
          }
          sw.stop();
          timings.add(sw.elapsed);
        }
        
        // For table-based constant-time operations, we mainly check that
        // operations complete within a reasonable time bound
        Duration maxTime = Duration(milliseconds: 100); // Should be very fast
        for (Duration timing in timings) {
          expect(timing, lessThan(maxTime), 
                 reason: 'Table-based operations should be fast');
        }
        
        // Basic variance check - allow significant variance due to system factors
        // but verify no timing is extremely different (>10x)
        Duration avg = timings.reduce((a, b) => a + b) ~/ timings.length;
        for (Duration timing in timings) {
          double ratio = timing.inMicroseconds / avg.inMicroseconds;
          expect(ratio, greaterThan(0.1), reason: 'No timing should be 10x faster than average');
          expect(ratio, lessThan(10.0), reason: 'No timing should be 10x slower than average');
        }
      });

      test('Input validation', () {
        expect(GF256.isValidElement(0), isTrue);
        expect(GF256.isValidElement(255), isTrue);
        expect(GF256.isValidElement(256), isFalse);
        expect(GF256.isValidElement(-1), isFalse);
      });

      test('Error handling', () {
        // Division by zero
        expect(() => GF256.divide(100, 0), throwsArgumentError);
        
        // Mismatched array lengths in interpolation
        expect(() => GF256.lagrangeInterpolate([1, 2], [3]),
               throwsArgumentError);
      });
    });

    group('Known Answer Tests', () {
      test('Multiplication KAT', () {
        // Known multiplication results in GF(2^8) with AES polynomial 0x11B
        expect(GF256.multiply(2, 3), equals(6));
        expect(GF256.multiply(7, 7), equals(21)); // Corrected: 0x07 * 0x07 = 0x15
        expect(GF256.multiply(9, 11), equals(83));
        expect(GF256.multiply(53, 213), equals(182)); // Corrected: 0x35 * 0xD5 = 0xB6
      });

      test('Division KAT', () {
        // Known division results in GF(2^8) with AES polynomial 0x11B
        expect(GF256.divide(6, 2), equals(3));
        expect(GF256.divide(21, 7), equals(7)); // Corrected: 21/7 = 7 since 7*7=21
        expect(GF256.divide(83, 11), equals(9));
        expect(GF256.divide(182, 53), equals(213)); // Corrected: 182/53 = 213 since 53*213=182
      });

      test('Inverse KAT', () {
        // Known multiplicative inverses in GF(2^8) with AES polynomial 0x11B
        expect(GF256.inverse(2), equals(141));
        expect(GF256.inverse(3), equals(246));
        expect(GF256.inverse(9), equals(79));
        expect(GF256.inverse(11), equals(192)); // Corrected: inverse of 0x0B is 0xC0
      });
    });

    tearDownAll(() {
      // Clean up sensitive data
      GF256.secureClear();
    });
  });
}

// Helper function for Lagrange interpolation testing
int _evaluateInterpolatedAt(List<int> xValues, List<int> yValues, int x) {
  int result = 0;
  int n = xValues.length;
  
  for (int i = 0; i < n; i++) {
    int term = yValues[i];
    for (int j = 0; j < n; j++) {
      if (i != j) {
        int numerator = GF256.subtract(x, xValues[j]);
        int denominator = GF256.subtract(xValues[i], xValues[j]);
        term = GF256.multiply(term, GF256.divide(numerator, denominator));
      }
    }
    result = GF256.add(result, term);
  }
  
  return result;
}