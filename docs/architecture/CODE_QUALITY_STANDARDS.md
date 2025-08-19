# Code Quality Standards

## Overview

This document establishes the mandatory code quality standards, guardrails, and compliance requirements for the SRSecrets project. These standards ensure security, maintainability, and architectural integrity across all domains.

## File Size and Structure Requirements

### 450-Line Maximum Rule

**Mandatory**: No single file may exceed 450 lines of code.

**Rationale**:
- Promotes single responsibility principle
- Improves code readability and maintainability
- Reduces cognitive load during code reviews
- Forces proper abstraction and modularization

**Enforcement**:
```bash
# Automated check in CI/CD pipeline
find lib -name "*.dart" -exec wc -l {} + | awk '$1 > 450 { print "File exceeds 450 lines: " $2 " (" $1 " lines)" }'
```

**Refactoring Strategies When Approaching Limit**:

1. **Extract Helper Classes**:
```dart
// BEFORE: Large service class (480 lines)
class PinServiceImpl {
  // Authentication logic
  // Validation logic  
  // Storage operations
  // History management
}

// AFTER: Extracted responsibilities (4 files, <200 lines each)
class PinServiceImpl {
  final PinValidator _validator;
  final AuthAttemptManager _attemptManager;
  // Core coordination logic only
}

class PinValidator {
  // PIN validation logic only
}

class AuthAttemptManager {
  // Lockout and attempt tracking only
}
```

2. **Extract Value Objects**:
```dart
// BEFORE: Large model class
class ShareSet {
  // Share data
  // Metadata
  // Validation
  // Serialization
  // Export formats
}

// AFTER: Focused classes
class ShareSet {
  final List<Share> shares;
  final ShareSetMetadata metadata;
  // Core data only
}

class ShareSetExporter {
  // Export format handling
}

class ShareSetValidator {
  // Validation logic
}
```

3. **Extract Mixins for Shared Behavior**:
```dart
// Shared validation behavior
mixin ValidationMixin {
  void validateNotNull(dynamic value, String fieldName) {
    if (value == null) {
      throw ArgumentError('$fieldName cannot be null');
    }
  }
}

// Applied to multiple classes
class Share with ValidationMixin {
  Share(int x, int y) {
    validateNotNull(x, 'x');
    validateNotNull(y, 'y');
  }
}
```

## Testing Requirements

### 100% Test Coverage Mandate

**Requirement**: Every class, method, and logical branch must have corresponding test coverage.

**Verification**:
```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Verify 100% coverage
lcov --summary coverage/lcov.info | grep "100.0%"
```

**Test Categories**:

1. **Unit Tests** (Required for all classes):
```dart
// Complete class coverage example
class GF256Test extends TestCase {
  
  @test
  void testAdd_validInputs_returnsCorrectResult() {
    // Test all arithmetic operations
  }
  
  @test
  void testMultiply_boundaryValues_handlesCorrectly() {
    // Test edge cases: 0, 1, 255
  }
  
  @test
  void testDivide_divisionByZero_throwsException() {
    // Test error conditions
  }
  
  @test
  void testLagrangeInterpolate_sufficientShares_reconstructsSecret() {
    // Test main use case
  }
}
```

2. **Integration Tests** (Required for critical paths):
```dart
// Cross-domain integration tests
class AuthenticationFlowTest extends IntegrationTest {
  
  @test
  void testFullPinSetupAndAuthentication() {
    // Test complete auth workflow
  }
  
  @test
  void testLockoutBehaviorIntegration() {
    // Test lockout across storage and service layers
  }
}
```

3. **Golden Tests** (Required for UI components):
```dart
// UI consistency verification
class WidgetGoldenTests extends TestCase {
  
  @test
  void testPinInputWidget_lightTheme_matchesGolden() {
    // Verify visual consistency
  }
  
  @test
  void testErrorDisplayWidget_variousStates_matchesGolden() {
    // Test all error states
  }
}
```

### Security-Focused Testing Requirements

**Cryptographic Operation Tests**:
```dart
class SecurityTest extends TestCase {
  
  @test
  void testConstantTimeOperations_timingAnalysis() {
    // Verify timing attack resistance
    final stopwatch = Stopwatch();
    
    // Test constant-time comparison
    for (int i = 0; i < 1000; i++) {
      stopwatch.start();
      cryptoProvider.constantTimeEquals(hash1, hash2);
      stopwatch.stop();
    }
    
    // Verify timing consistency (within 5% variance)
    verifyTimingConsistency(stopwatch.elapsedMicroseconds);
  }
  
  @test
  void testSecureRandom_randomnessQuality() {
    // Statistical randomness tests
    final samples = <int>[];
    for (int i = 0; i < 10000; i++) {
      samples.add(SecureRandom.nextGF256Element());
    }
    
    // Chi-square test for uniform distribution
    verifyUniformDistribution(samples);
  }
  
  @test
  void testMemorySanitization_sensitiveDaLaClearance() {
    // Verify secure deletion
    final sensitiveData = Uint8List.fromList([1, 2, 3, 4]);
    final pointer = sensitiveData.buffer.asByteData();
    
    // Use data
    processSecretData(sensitiveData);
    
    // Verify zeroing
    verifyMemoryCleared(pointer);
  }
}
```

## SOLID Principles Compliance

### Single Responsibility Principle (SRP)

**Verification Checklist**:
- [ ] Each class has one clear responsibility
- [ ] Class name clearly indicates its purpose
- [ ] No more than 5-7 public methods per class
- [ ] Methods are cohesive and related

**Example Compliance**:
```dart
// ✅ GOOD: Single responsibility
class PinValidator {
  void validateLength(String pin) { /* */ }
  void validateDigitsOnly(String pin) { /* */ }
  void validateComplexity(String pin) { /* */ }
}

// ❌ BAD: Multiple responsibilities
class PinService {
  void validatePin(String pin) { /* */ }
  void hashPin(String pin) { /* */ }
  void storePin(PinHash hash) { /* */ }
  void checkLockout() { /* */ }
  void updateAttemptHistory() { /* */ }
}
```

### Open/Closed Principle (OCP)

**Implementation Pattern**:
```dart
// Abstract base for extension
abstract class ICryptoProvider {
  Future<PinHash> hashPin(String pin);
  Future<bool> verifyPin(String pin, PinHash hash);
}

// Concrete implementations are closed to modification
class Pbkdf2CryptoProvider implements ICryptoProvider {
  @override
  Future<PinHash> hashPin(String pin) {
    // PBKDF2 implementation - closed to modification
  }
}

// New implementations extend without modifying existing code
class ScryptCryptoProvider implements ICryptoProvider {
  @override
  Future<PinHash> hashPin(String pin) {
    // Scrypt implementation - extension, not modification
  }
}
```

### Liskov Substitution Principle (LSP)

**Contract Verification**:
```dart
// Base contract requirements
abstract class ISecureRandom {
  /// Returns cryptographically secure random byte (0-255)
  /// Precondition: None
  /// Postcondition: 0 <= result <= 255, cryptographically secure
  int nextGF256Element();
}

// Implementation must honor the contract exactly
class SecureRandom implements ISecureRandom {
  @override
  int nextGF256Element() {
    // Must return 0-255, must be cryptographically secure
    return Random.secure().nextInt(256);
  }
}

// LSP compliance test
class LSPComplianceTest extends TestCase {
  void testSubstitutability() {
    ISecureRandom random = SecureRandom();
    // Should work with any ISecureRandom implementation
    verifyRandomnessQuality(random);
  }
}
```

### Interface Segregation Principle (ISP)

**Focused Interface Design**:
```dart
// ✅ GOOD: Segregated interfaces
abstract class IPinStorage {
  Future<void> storePinHash(PinHash hash);
  Future<PinHash?> loadPinHash();
}

abstract class IAttemptStorage {
  Future<void> storeAttemptHistory(AuthAttemptHistory history);
  Future<AuthAttemptHistory> loadAttemptHistory();
}

// ❌ BAD: Fat interface
abstract class IStorageService {
  Future<void> storePinHash(PinHash hash);
  Future<PinHash?> loadPinHash();
  Future<void> storeAttemptHistory(AuthAttemptHistory history);
  Future<AuthAttemptHistory> loadAttemptHistory();
  Future<void> storeSecretInfo(SecretInfo info);
  Future<List<SecretInfo>> loadSecretHistory();
}
```

### Dependency Inversion Principle (DIP)

**Dependency Injection Pattern**:
```dart
// High-level module depends on abstraction
class PinServiceImpl {
  final IPinCryptoProvider _cryptoProvider;
  final IPinStorageRepository _storageRepository;
  
  // Constructor injection - depends on abstractions
  PinServiceImpl({
    required IPinCryptoProvider cryptoProvider,
    required IPinStorageRepository storageRepository,
  }) : _cryptoProvider = cryptoProvider,
       _storageRepository = storageRepository;
}

// Concrete dependencies injected at composition root
class ServiceComposition {
  static PinServiceImpl createPinService() {
    return PinServiceImpl(
      cryptoProvider: Pbkdf2CryptoProvider(),
      storageRepository: SecureStorageRepository(),
    );
  }
}
```

## Documentation Standards

### Domain Map Requirements

**Mandatory**: Every domain must maintain an accurate `map.json` file.

**Structure Requirements**:
```json
{
  "domain_name": "domain_name",
  "purpose": "Clear, concise domain purpose statement",
  "classes": [
    {
      "class_name": "ClassName",
      "purpose": "Single sentence describing class responsibility",
      "methods": [
        {
          "method_name": "methodName",
          "purpose": "What this method accomplishes",
          "contract": {
            "inputs": ["param: Type with description"],
            "outputs": ["ReturnType with description"],
            "preconditions": ["Conditions that must be true when called"],
            "postconditions": ["Guarantees after successful execution"]
          },
          "dependencies": ["Classes/methods this depends on"]
        }
      ],
      "dependencies": ["External dependencies"]
    }
  ]
}
```

**Map Validation**:
```dart
// Automated domain map validation
class DomainMapValidator {
  void validateMapAccuracy(String domainPath) {
    final map = loadDomainMap(domainPath);
    final actualClasses = scanDartFiles(domainPath);
    
    // Verify all classes documented
    for (final clazz in actualClasses) {
      assert(map.classes.any((c) => c.name == clazz.name),
        'Class ${clazz.name} not documented in domain map');
    }
    
    // Verify all methods documented
    for (final clazz in actualClasses) {
      final mapClass = map.classes.firstWhere((c) => c.name == clazz.name);
      for (final method in clazz.methods) {
        assert(mapClass.methods.any((m) => m.name == method.name),
          'Method ${method.name} not documented');
      }
    }
  }
}
```

### Code Documentation Requirements

**Mandatory Documentation**:

1. **Class-Level Documentation**:
```dart
/// Implements GF(2^8) finite field arithmetic with constant-time operations
/// to prevent side-channel attacks.
///
/// This class provides the mathematical foundation for Shamir's Secret Sharing
/// by implementing addition, multiplication, division, and polynomial 
/// operations in the Galois Field GF(2^8).
///
/// All operations are implemented using lookup tables to ensure constant-time
/// execution, preventing timing-based side-channel attacks.
class GF256 {
  // Implementation
}
```

2. **Method-Level Documentation**:
```dart
/// Performs Lagrange interpolation to reconstruct the secret from shares.
///
/// This method implements the mathematical reconstruction process for
/// Shamir's Secret Sharing by computing the constant term of the
/// polynomial that passes through the given points.
///
/// @param xValues The x-coordinates of the shares (must be unique)
/// @param yValues The y-coordinates of the shares
/// @returns The reconstructed secret (constant term of polynomial)
///
/// @precondition xValues.length == yValues.length
/// @precondition xValues.length >= threshold
/// @precondition All values are valid GF(256) elements
/// @precondition All xValues are unique and non-zero
///
/// @postcondition Returns the original secret value
/// @postcondition Operation completes in constant time
static int lagrangeInterpolate(List<int> xValues, List<int> yValues) {
  // Implementation with comprehensive validation
}
```

3. **Security-Critical Documentation**:
```dart
/// Compares two byte arrays in constant time to prevent timing attacks.
///
/// SECURITY CRITICAL: This method must complete in exactly the same time
/// regardless of:
/// - The input array lengths (up to maximum)
/// - The position of the first differing byte
/// - The values being compared
///
/// This prevents timing-based side-channel attacks where an attacker
/// could determine hash prefixes by measuring comparison times.
///
/// @param a First byte array to compare
/// @param b Second byte array to compare  
/// @returns true if arrays are identical, false otherwise
///
/// @security Timing-attack resistant implementation required
/// @warning Do not modify this method without security review
static bool constantTimeEquals(Uint8List a, Uint8List b) {
  // Constant-time implementation
}
```

## Code Review Standards

### Review Checklist

**Mandatory Review Points**:

- [ ] **File Size**: Does not exceed 450 lines
- [ ] **SOLID Compliance**: Each principle verified
- [ ] **Test Coverage**: 100% coverage with meaningful tests
- [ ] **Security Review**: Cryptographic operations reviewed
- [ ] **Documentation**: All public APIs documented
- [ ] **Domain Boundaries**: No cross-domain violations
- [ ] **Error Handling**: Appropriate exception handling
- [ ] **Performance**: No obvious performance issues

### Security Review Requirements

**Cryptographic Code Reviews**:
- [ ] Constant-time operations verified
- [ ] No hardcoded cryptographic values
- [ ] Proper randomness sources used
- [ ] Secure memory handling implemented
- [ ] Side-channel attack resistance verified

**Authentication Code Reviews**:
- [ ] PBKDF2 parameters appropriate
- [ ] Lockout logic prevents brute force
- [ ] Timing attack prevention implemented
- [ ] Secure storage mechanisms used

### Automated Quality Gates

**CI/CD Pipeline Requirements**:

```yaml
# .github/workflows/quality.yml
name: Quality Gates

on: [push, pull_request]

jobs:
  quality_checks:
    runs-on: ubuntu-latest
    steps:
      - name: Check file sizes
        run: |
          find lib -name "*.dart" -exec wc -l {} + | \
          awk '$1 > 450 { print "File exceeds 450 lines: " $2; exit 1 }'
      
      - name: Run tests with coverage
        run: |
          flutter test --coverage
          lcov --summary coverage/lcov.info | grep -q "100.0%"
      
      - name: Validate domain maps
        run: dart run tools/validate_domain_maps.dart
      
      - name: Security audit
        run: dart run tools/security_audit.dart
      
      - name: SOLID compliance check
        run: dart run tools/solid_analyzer.dart
```

## Performance Standards

### Response Time Requirements

**UI Performance**:
- Cold start: < 3 seconds
- Screen transitions: < 100ms
- PIN input response: < 50ms
- Form validation: < 100ms

**Cryptographic Performance**:
- PIN hashing: 100-500ms (calibrated)
- Share generation: < 1 second
- Secret reconstruction: < 500ms
- Field operations: < 1µs each

### Memory Management Standards

**Memory Usage**:
- Peak usage: < 200MB
- Memory leaks: Zero tolerance
- Sensitive data: Immediate cleanup
- Garbage collection: Predictable patterns

**Verification**:
```dart
class PerformanceTest extends TestCase {
  @test
  void testMemoryUsage_normalOperations_withinLimits() {
    final initialMemory = getMemoryUsage();
    
    // Perform typical operations
    performSecretSharing();
    
    final peakMemory = getMemoryUsage();
    expect(peakMemory - initialMemory, lessThan(200 * 1024 * 1024));
  }
  
  @test 
  void testResponseTime_uiInteractions_meetRequirements() {
    final stopwatch = Stopwatch()..start();
    
    // Trigger UI interaction
    triggerPinInput();
    
    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(50));
  }
}
```

## Compliance Verification

### Automated Compliance Checks

**Daily Quality Reports**:
```dart
// tools/quality_report.dart
class QualityReportGenerator {
  void generateDailyReport() {
    final report = QualityReport()
      ..filesSizeCompliance = checkFileSizes()
      ..testCoverage = calculateCoverage()
      ..solidCompliance = analyzeSolidPrinciples()
      ..securityIssues = runSecurityScan()
      ..documentationCoverage = checkDocumentation();
    
    report.generateReport();
  }
}
```

### Quality Metrics Dashboard

**Tracked Metrics**:
- File size distribution and violations
- Test coverage percentage by domain
- SOLID principle compliance scores  
- Security issue count and severity
- Documentation coverage percentage
- Code review approval rates
- Performance benchmark results

### Enforcement Mechanisms

**Pre-commit Hooks**:
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check file sizes
if find lib -name "*.dart" -exec wc -l {} + | awk '$1 > 450 { exit 1 }'; then
    echo "❌ File size violation: Files exceed 450 line limit"
    exit 1
fi

# Run quick tests
if ! flutter test --coverage > /dev/null 2>&1; then
    echo "❌ Tests failing"
    exit 1
fi

# Validate domain maps
if ! dart run tools/validate_maps.dart > /dev/null 2>&1; then
    echo "❌ Domain maps out of sync"
    exit 1
fi

echo "✅ Quality checks passed"
```

These quality standards ensure that SRSecrets maintains enterprise-grade code quality, security, and maintainability throughout its development lifecycle.