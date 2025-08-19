# Cryptographic API Reference

## Overview

This document provides comprehensive API documentation for the SRSecrets cryptographic domain. The API is organized in layers, from high-level convenience methods to low-level mathematical primitives, allowing developers to choose the appropriate level of abstraction for their use case.

## API Hierarchy

### Layer 1: High-Level API
- `ShamirSecretSharing` - Main facade for secret sharing operations
- `ShamirSession` - Interactive secret reconstruction
- `ParticipantPackage` - Distribution management

### Layer 2: Component API  
- `ShareGenerator` - Share creation services
- `SecretReconstructor` - Share reconstruction services
- `Share`, `ShareSet` - Data structures

### Layer 3: Primitive API
- `GF256` - Finite field arithmetic
- `PolynomialGenerator` - Polynomial operations
- `SecureRandom` - Cryptographic random numbers

## High-Level API

### ShamirSecretSharing Class

Primary interface for Shamir's Secret Sharing operations.

#### Static Methods

##### splitByte()
```dart
static SplitResult splitByte({
  required int secret,
  required int threshold,
  required int shares,
})
```

**Description**: Split a single byte secret into shares.

**Parameters**:
- `secret` (int): Secret byte value (0-255)
- `threshold` (int): Minimum shares needed for reconstruction (≥2)
- `shares` (int): Total number of shares to generate (≤255)

**Returns**: `SplitResult` containing generated shares and metadata

**Throws**:
- `ArgumentError` if secret not in range 0-255
- `ArgumentError` if threshold < 2
- `ArgumentError` if threshold > shares
- `ArgumentError` if shares > 255

**Example**:
```dart
final result = ShamirSecretSharing.splitByte(
  secret: 42,
  threshold: 3,
  shares: 5,
);

// Access individual shares
final share0 = result.getShare(0);
print('Share 0: x=${share0?.x}, y=${share0?.y}');

// Export shares for distribution
final base64Shares = result.toBase64List();
```

##### splitBytes()
```dart
static MultiSplitResult splitBytes({
  required Uint8List secret,
  required int threshold,
  required int shares,
})
```

**Description**: Split a byte array into shares using parallel Shamir sharing.

**Parameters**:
- `secret` (Uint8List): Secret bytes to split (must not be empty)
- `threshold` (int): Minimum shares needed for reconstruction (≥2)  
- `shares` (int): Total number of shares to generate (≤255)

**Returns**: `MultiSplitResult` containing share sets for each participant

**Throws**:
- `ArgumentError` if secret is empty
- `ArgumentError` if threshold < 2
- `ArgumentError` if threshold > shares
- `ArgumentError` if shares > 255

**Example**:
```dart
final secretData = Uint8List.fromList([1, 2, 3, 4, 5]);
final result = ShamirSecretSharing.splitBytes(
  secret: secretData,
  threshold: 3,
  shares: 5,
);

// Create distribution packages
final packages = result.createDistributionPackages();
for (int i = 0; i < packages.length; i++) {
  print('Package ${i + 1}: ${packages[i].toBase64()}');
}
```

##### splitString()
```dart
static MultiSplitResult splitString({
  required String secret,
  required int threshold,
  required int shares,
})
```

**Description**: Split a UTF-8 string into shares.

**Parameters**:
- `secret` (String): Secret string to split (must not be empty)
- `threshold` (int): Minimum shares needed for reconstruction (≥2)
- `shares` (int): Total number of shares to generate (≤255)

**Returns**: `MultiSplitResult` with UTF-8 encoding metadata

**Example**:
```dart
final result = ShamirSecretSharing.splitString(
  secret: "my-secret-password",
  threshold: 3,
  shares: 5,
);

// Metadata includes encoding information
print('Type: ${result.metadata['type']}'); // 'string'
print('Encoding: ${result.metadata['encoding']}'); // 'utf8'
```

##### combineByte()
```dart
static int combineByte({
  required List<Share> shares,
  required int threshold,
})
```

**Description**: Reconstruct a byte secret from shares.

**Parameters**:
- `shares` (List<Share>): Share list (length ≥ threshold)
- `threshold` (int): Required number of shares

**Returns**: Reconstructed secret byte (0-255)

**Throws**:
- `ArgumentError` if insufficient shares provided

**Example**:
```dart
// Assuming we have shares from previous split
final reconstructed = ShamirSecretSharing.combineByte(
  shares: selectedShares,
  threshold: 3,
);
print('Reconstructed secret: $reconstructed');
```

##### combineBytes()
```dart
static Uint8List combineBytes({
  required List<ShareSet> shareSets,
})
```

**Description**: Reconstruct byte array from share sets.

**Parameters**:
- `shareSets` (List<ShareSet>): Share sets from participants

**Returns**: Reconstructed secret bytes

**Throws**:
- `ArgumentError` if share sets is empty
- `ArgumentError` if insufficient share sets for threshold

**Example**:
```dart
// Collect share sets from participants  
final shareSets = [shareSet1, shareSet2, shareSet3];
final reconstructed = ShamirSecretSharing.combineBytes(
  shareSets: shareSets,
);
print('Reconstructed ${reconstructed.length} bytes');
```

##### combineString()
```dart
static String combineString({
  required List<ShareSet> shareSets,
})
```

**Description**: Reconstruct UTF-8 string from share sets.

**Parameters**:
- `shareSets` (List<ShareSet>): Share sets from participants

**Returns**: Reconstructed secret string

**Throws**:
- `ArgumentError` if share sets is empty
- `FormatException` if reconstructed bytes are not valid UTF-8

**Example**:
```dart
final reconstructed = ShamirSecretSharing.combineString(
  shareSets: collectedShareSets,
);
print('Reconstructed password: $reconstructed');
```

##### verifyShares()
```dart
static bool verifyShares({
  required List<Share> shares,
  required int threshold,
})
```

**Description**: Verify shares can reconstruct a secret without actually reconstructing.

**Returns**: `true` if reconstruction is possible, `false` otherwise

##### createSession()
```dart
static ShamirSession createSession({
  required int threshold,
  required int totalShares,
})
```

**Description**: Create an interactive session for progressive share collection.

**Returns**: `ShamirSession` instance for managing reconstruction process

**Example**:
```dart
final session = ShamirSecretSharing.createSession(
  threshold: 3,
  totalShares: 5,
);

// Add shares as they become available
session.addShareSet(shareSet1);
session.addShareSet(shareSet2);
session.addShareSet(shareSet3);

if (session.isReconstructed) {
  final secret = session.secretString;
}
```

### SplitResult Class

Result container for single-byte secret splitting.

#### Properties
- `shares` (List<SecureShare>): Generated shares with integrity checks
- `threshold` (int): Threshold value used
- `totalShares` (int): Total number of shares generated
- `metadata` (Map<String, dynamic>): Additional information

#### Methods

##### getShare()
```dart
SecureShare? getShare(int index)
```

**Description**: Get share at specific index.

**Returns**: Share at index or `null` if out of bounds

##### toJson()
```dart
List<Map<String, dynamic>> toJson()
```

**Description**: Export shares as JSON array.

##### toBase64List()
```dart
List<String> toBase64List()
```

**Description**: Export shares as base64 strings for transmission.

### MultiSplitResult Class

Result container for multi-byte secret splitting.

#### Properties
- `shareSets` (List<ShareSet>): Generated share sets for each participant
- `threshold` (int): Threshold value used
- `totalShares` (int): Total number of share sets generated
- `secretLength` (int): Length of original secret in bytes
- `metadata` (Map<String, dynamic>): Additional information

#### Methods

##### getShareSet()
```dart
ShareSet? getShareSet(int index)
```

##### toJson()
```dart
List<Map<String, dynamic>> toJson()
```

##### toBase64List()
```dart
List<String> toBase64List()
```

##### createDistributionPackages()
```dart
List<ParticipantPackage> createDistributionPackages()
```

**Description**: Create packages for distribution to participants with instructions.

### ShamirSession Class

Interactive session for progressive secret reconstruction.

#### Properties
- `threshold` (int): Required number of shares
- `totalShares` (int): Total shares in the scheme
- `progress` (double): Current progress (0.0 to 1.0)
- `canReconstruct` (bool): Whether reconstruction is possible
- `isReconstructed` (bool): Whether secret has been reconstructed
- `secretBytes` (Uint8List?): Reconstructed secret bytes
- `secretString` (String?): Reconstructed secret as UTF-8 string
- `sharesCollected` (int): Number of shares collected
- `sharesNeeded` (int): Number of additional shares needed

#### Methods

##### addShareSet()
```dart
bool addShareSet(ShareSet shareSet)
```

**Description**: Add a share set to the session.

**Returns**: `true` if reconstruction completed, `false` otherwise

**Example**:
```dart
final session = ShamirSecretSharing.createSession(
  threshold: 3, 
  totalShares: 5,
);

// Progressive collection
print('Progress: ${(session.progress * 100).toInt()}%');
print('Need ${session.sharesNeeded} more shares');

final completed = session.addShareSet(shareSet1);
if (completed) {
  print('Reconstruction complete!');
  print('Secret: ${session.secretString}');
}
```

##### reset()
```dart
void reset()
```

**Description**: Reset the session to initial state.

##### getStatus()
```dart
Map<String, dynamic> getStatus()
```

**Description**: Get current session status information.

## Component API

### ShareGenerator Class

Factory for creating shares from secrets.

#### Static Methods

##### generateShares()
```dart
static List<Share> generateShares({
  required int secret,
  required int threshold,
  required int totalShares,
})
```

**Description**: Generate basic shares for a single byte secret.

##### generateSecureShares()
```dart
static List<SecureShare> generateSecureShares({
  required int secret,
  required int threshold,
  required int totalShares,
  String? identifier,
  int? version,
})
```

**Description**: Generate shares with integrity checksums and metadata.

##### generateShareSets()
```dart
static List<ShareSet> generateShareSets({
  required Uint8List secretBytes,
  required int threshold,
  required int totalShares,
  String? description,
})
```

**Description**: Generate share sets for multi-byte secrets.

### SecretReconstructor Class

Service for reconstructing secrets from shares.

#### Static Methods

##### reconstructSecret()
```dart
static int reconstructSecret(List<Share> shares)
```

**Description**: Reconstruct single-byte secret using Lagrange interpolation.

##### reconstructFromShareSets()
```dart
static Uint8List reconstructFromShareSets(List<ShareSet> shareSets)
```

**Description**: Reconstruct multi-byte secret from share sets.

##### canReconstruct()
```dart
static bool canReconstruct(List<Share> shares, int threshold)
```

**Description**: Check if shares are sufficient for reconstruction.

### Share Class

Basic share data structure.

#### Constructor
```dart
const Share({
  required int x,
  required int y,
})
```

#### Properties
- `x` (int): X-coordinate (share index) in GF(2^8)
- `y` (int): Y-coordinate (share value) in GF(2^8)

#### Methods

##### toJson()
```dart
Map<String, dynamic> toJson()
```

##### fromJson()
```dart
factory Share.fromJson(Map<String, dynamic> json)
```

##### toBase64()
```dart
String toBase64()
```

##### isValid()
```dart
bool isValid()
```

**Description**: Validate that share has legal field values.

### SecureShare Class

Extended share with integrity verification.

#### Constructor
```dart
SecureShare({
  required int x,
  required int y,
  required int threshold,
  required int totalShares,
  String? identifier,
  int? version,
})
```

#### Additional Properties
- `threshold` (int): Threshold parameter
- `totalShares` (int): Total shares parameter
- `checksum` (int): Integrity checksum
- `identifier` (String?): Optional identifier
- `version` (int): Version number

#### Methods

##### hasValidChecksum()
```dart
bool hasValidChecksum()
```

**Description**: Verify share integrity against stored checksum.

### ShareSet Class

Container for multiple shares representing a multi-byte secret.

#### Constructor
```dart
ShareSet({
  required List<Share> shares,
  required ShareSetMetadata metadata,
})
```

#### Properties
- `shares` (List<Share>): Shares for each byte of the secret
- `metadata` (ShareSetMetadata): Metadata including threshold and participant info

#### Methods

##### getShareAt()
```dart
Share? getShareAt(int index)
```

##### toJson()
```dart
Map<String, dynamic> toJson()
```

##### toBase64()
```dart
String toBase64()
```

## Primitive API

### GF256 Class

Finite field GF(2^8) arithmetic operations.

#### Static Methods

##### add()
```dart
static int add(int a, int b)
```

**Description**: Addition in GF(2^8) using XOR.

**Performance**: ~0.002μs per operation

**Example**:
```dart
final sum = GF256.add(5, 10); // Returns 5 ⊕ 10 = 15
```

##### subtract()
```dart
static int subtract(int a, int b)
```

**Description**: Subtraction in GF(2^8) (same as addition).

##### multiply()
```dart
static int multiply(int a, int b)
```

**Description**: Multiplication in GF(2^8) using lookup table.

**Performance**: ~0.003μs per operation

**Example**:
```dart
final product = GF256.multiply(3, 7); // GF multiplication
```

##### divide()
```dart
static int divide(int a, int b)
```

**Description**: Division in GF(2^8) using multiplicative inverse.

**Performance**: ~0.011μs per operation

**Throws**: `ArgumentError` if dividing by zero

##### power()
```dart
static int power(int a, int n)
```

**Description**: Compute a^n in GF(2^8) using square-and-multiply.

**Performance**: ~0.11μs per operation

##### inverse()
```dart
static int inverse(int a)
```

**Description**: Compute multiplicative inverse in GF(2^8).

**Returns**: Inverse of `a`, or 0 for input 0

##### evaluatePolynomial()
```dart
static int evaluatePolynomial(List<int> coefficients, int x)
```

**Description**: Evaluate polynomial at x using Horner's method.

**Parameters**:
- `coefficients`: Polynomial coefficients (constant term first)
- `x`: Evaluation point

##### lagrangeInterpolate()
```dart
static int lagrangeInterpolate(List<int> xValues, List<int> yValues)
```

**Description**: Lagrange interpolation returning constant term.

**Performance**: ~0.001ms for 5 points

**Example**:
```dart
final xCoords = [1, 2, 3];
final yCoords = [10, 20, 30];
final secret = GF256.lagrangeInterpolate(xCoords, yCoords);
```

##### isValidElement()
```dart
static bool isValidElement(int value)
```

**Description**: Check if value is valid GF(2^8) element (0-255).

##### secureClear()
```dart
static void secureClear()
```

**Description**: Attempt to clear sensitive lookup tables from memory.

### PolynomialGenerator Class

Polynomial generation and evaluation services.

#### Static Methods

##### generatePolynomial()
```dart
static List<int> generatePolynomial({
  required int secret,
  required int threshold,
  int? fieldSize,
})
```

**Description**: Generate random polynomial with secret as constant term.

**Performance**: ~122μs per operation

**Parameters**:
- `secret`: Secret value (constant term)
- `threshold`: Polynomial degree + 1
- `fieldSize`: Field size (default 256)

**Returns**: List of polynomial coefficients

**Example**:
```dart
final poly = PolynomialGenerator.generatePolynomial(
  secret: 42,
  threshold: 3,
);
// poly[0] == 42 (constant term)
// poly[1], poly[2] are random coefficients
```

##### generateEvaluationPoints()
```dart
static List<int> generateEvaluationPoints(int n)
```

**Description**: Generate n unique non-zero x-values for shares.

**Performance**: ~4ms for 100 points

**Returns**: Sorted list of unique evaluation points

##### evaluatePolynomial()
```dart
static int evaluatePolynomial(List<int> coefficients, int x)
```

**Description**: Evaluate polynomial at x in GF(2^8).

**Performance**: ~0.033μs per operation

### SecureRandom Class

Cryptographically secure random number generator.

#### Instance Methods

##### instance
```dart
static SecureRandom get instance
```

**Description**: Get singleton instance.

##### nextByte()
```dart
int nextByte()
```

**Description**: Generate random byte (0-255).

**Performance**: ~31μs per operation

##### nextGF256Element()
```dart
int nextGF256Element()
```

**Description**: Generate random GF(2^8) element.

**Performance**: ~32μs per operation

##### nextNonZeroGF256Element()
```dart
int nextNonZeroGF256Element()  
```

**Description**: Generate random non-zero GF(2^8) element (1-255).

##### nextBytes()
```dart
Uint8List nextBytes(int length)
```

**Description**: Generate array of random bytes.

**Performance**: ~985μs for 32 bytes

## Error Handling

### Exception Types

#### ArgumentError
- Invalid parameter values
- Out-of-range inputs  
- Insufficient shares for reconstruction

#### FormatException
- Invalid share format during deserialization
- Corrupt share data
- Invalid UTF-8 encoding

### Error Messages

Error messages are designed to be informative without exposing sensitive information:

```dart
// Good: Informative but safe
'Need at least 3 shares, got 2'

// Bad: Potentially exposes sensitive data  
'Cannot reconstruct secret "password123" with 2 shares'
```

## Performance Guidelines

### Optimization Recommendations

**For High-Frequency Operations**:
- Cache `GF256` tables by calling any operation once
- Reuse `PolynomialGenerator` instances where possible
- Batch process multiple secrets together

**For Memory-Constrained Environments**:
- Call `GF256.secureClear()` after operations
- Process secrets in chunks for large data
- Use streaming APIs for very large secrets

**For Time-Critical Applications**:
- Pre-warm GF256 tables during application startup
- Use `verifyShares()` before expensive reconstruction
- Consider parallel processing for independent operations

### Performance Benchmarks

Current performance on macOS 15.5:

| Operation | Time | Memory |
|-----------|------|--------|
| Single byte split | 0.23ms | <1MB |
| Multi-byte split (64B) | 42.5ms | <5MB |  
| String split (60 chars) | 22.2ms | <3MB |
| GF256 operations | <0.1μs | 65KB tables |
| Large shares (255) | 50ms | <10MB |

## Security Considerations

### Safe Usage Patterns

**Always validate inputs**:
```dart
if (!GF256.isValidElement(value)) {
  throw ArgumentError('Invalid field element: $value');
}
```

**Use secure shares for production**:
```dart
// Prefer SecureShare over basic Share
final secureShares = ShareGenerator.generateSecureShares(
  secret: secret,
  threshold: threshold, 
  totalShares: shares,
);
```

**Clear sensitive data promptly**:
```dart
// After reconstruction
final secret = reconstructedBytes;
// Use secret immediately
processSecret(secret);
// Clear from memory
secret.fillRange(0, secret.length, 0);
```

### Anti-Patterns to Avoid

**Don't log sensitive information**:
```dart
// BAD
print('Share value: ${share.y}');
// GOOD  
print('Share ${share.x} received');
```

**Don't reuse random values**:
```dart
// BAD
final randomCoeff = SecureRandom.instance.nextGF256Element();
final poly1 = [secret1, randomCoeff];
final poly2 = [secret2, randomCoeff]; // NEVER reuse!
```

**Don't ignore threshold requirements**:
```dart
// BAD
if (shares.length >= 1) { // Should check against threshold
  final secret = SecretReconstructor.reconstructSecret(shares);
}
```

## Migration Guide

### Upgrading from Basic to Secure Shares

```dart
// Old approach
final basicShares = ShareGenerator.generateShares(
  secret: secret, threshold: 3, totalShares: 5
);

// New approach  
final secureShares = ShareGenerator.generateSecureShares(
  secret: secret, threshold: 3, totalShares: 5,
  identifier: 'backup-key-2024',
  version: 1,
);
```

### Interactive to Batch Processing

```dart
// Old interactive approach
final session = ShamirSecretSharing.createSession(
  threshold: 3, totalShares: 5
);
for (final shareSet in shareSets) {
  session.addShareSet(shareSet);
}
final secret = session.secretBytes;

// New batch approach
final secret = ShamirSecretSharing.combineBytes(
  shareSets: shareSets.take(3).toList()
);
```

## Support and Troubleshooting

### Common Issues

**"Need at least N shares" error**:
- Verify you have collected sufficient shares
- Check that shares have unique x-coordinates
- Validate share integrity with `hasValidChecksum()`

**"Invalid field element" error**:
- Ensure all values are in range 0-255
- Check for data corruption during transmission
- Verify proper deserialization from storage format

**Performance slower than expected**:
- Ensure GF256 tables are pre-initialized
- Check for memory pressure causing garbage collection
- Profile with benchmarks to identify bottlenecks

### Debug Information

Enable debug logging for troubleshooting:

```dart
void debugShareGeneration() {
  final result = ShamirSecretSharing.splitByte(
    secret: 42, threshold: 3, shares: 5
  );
  
  print('Generated ${result.shares.length} shares');
  print('Threshold: ${result.threshold}');
  print('Metadata: ${result.metadata}');
  
  // Verify round-trip
  final reconstructed = ShamirSecretSharing.combineByte(
    shares: result.shares.take(3).toList(),
    threshold: 3,
  );
  print('Round-trip successful: ${reconstructed == 42}');
}
```

This completes the comprehensive API documentation for the SRSecrets cryptographic domain. The API provides multiple levels of abstraction while maintaining security and performance requirements suitable for production cryptographic applications.