/// Share Generator for Shamir's Secret Sharing
///
/// Generates shares from secrets using polynomial evaluation over GF(256).
library;

import 'dart:typed_data';
import '../polynomial/polynomial_generator.dart';
import '../random/secure_random.dart';
import 'share.dart';

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
