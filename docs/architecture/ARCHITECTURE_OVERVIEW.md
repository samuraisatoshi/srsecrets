# SRSecrets Architecture Overview

## System Architecture Summary

SRSecrets implements a security-first, air-gapped Flutter application for Shamir's Secret Sharing with Domain-Driven Design (DDD) principles and strict adherence to SOLID architectural patterns.

## Architecture Philosophy

### Core Principles
- **Security by Design**: Every component prioritizes cryptographic security and data protection
- **Air-Gapped Operation**: Zero network connectivity, complete local operation
- **Domain-Driven Design**: Clear domain boundaries with explicit business logic separation
- **SOLID Compliance**: All components follow SOLID principles for maintainability and extensibility
- **Minimal Attack Surface**: Restricted dependencies and secure coding practices

### Quality Standards
- **Maximum 450 lines per file**: Enforced refactoring for focused components
- **100% test coverage**: Comprehensive unit and integration testing
- **Constant-time operations**: Timing attack prevention in cryptographic operations
- **Secure memory handling**: Proper data sanitization and secure deletion

## Domain Architecture

### Three-Domain Structure

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CRYPTO        │    │      AUTH       │    │  PRESENTATION   │
│   DOMAIN        │    │     DOMAIN      │    │    DOMAIN       │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • GF256 Math    │    │ • PIN Service   │    │ • State Mgmt    │
│ • Polynomial    │    │ • PBKDF2 Hash   │    │ • UI Components │
│ • Share Gen     │    │ • Lockout       │    │ • Navigation    │
│ • Reconstruction│    │ • Storage       │    │ • Theming       │
│ • Secure Random │    │ • Auth History  │    │ • Validation    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 1. Crypto Domain (Core Domain)
**Purpose**: Cryptographic primitives and Shamir's Secret Sharing implementation

**Key Components**:
- **GF256**: Galois Field GF(2^8) arithmetic with constant-time operations
- **PolynomialGenerator**: Secure random polynomial generation for secret sharing
- **SecureRandom**: Cryptographically secure random number generation
- **Share/ShareSet**: Share data structures with serialization and validation
- **SecretReconstructor**: Lagrange interpolation for secret reconstruction
- **ShamirSecretSharing**: High-level API facade for secret sharing operations

**Security Features**:
- Constant-time field arithmetic to prevent timing attacks
- Cryptographically secure randomness for polynomial coefficients
- Share integrity validation with checksums
- Secure memory handling for sensitive data

### 2. Auth Domain (Supporting Domain)
**Purpose**: PIN-based authentication with lockout protection

**Key Components**:
- **PinServiceImpl**: Complete authentication business logic
- **Pbkdf2CryptoProvider**: PBKDF2-HMAC-SHA256 with timing attack protection
- **SecureStorageRepository**: Air-gapped file storage with XOR encryption
- **AuthAttemptHistory**: Progressive lockout management
- **PinHash**: Immutable value objects for secure hash storage

**Security Features**:
- PBKDF2 with configurable iterations (calibrated to device performance)
- Progressive lockout with exponential backoff
- Constant-time hash comparison
- Secure file deletion with multiple overwrites
- XOR encryption for stored authentication data

### 3. Presentation Domain (Supporting Domain)
**Purpose**: Flutter UI with state management and user interactions

**Key Components**:
- **AuthProvider**: Authentication state management with ChangeNotifier
- **SecretProvider**: Secret sharing operation state management
- **Screen Components**: PIN setup, login, secret creation, and reconstruction
- **Custom Widgets**: PIN input, share cards, and form components
- **AppTheme**: Material Design 3 theming with accessibility support

**UI Features**:
- Responsive design for multiple screen sizes
- Material Design 3 with light/dark theme support
- Accessibility compliance (WCAG 2.1 AA)
- Custom PIN input with numeric keypad
- Secure clipboard integration for share distribution

## Layer Architecture

### Layered Structure
```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Screens   │  │  Widgets    │  │  Providers  │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│                     SERVICE LAYER                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ Pin Service │  │  Shamir     │  │  Secure     │        │
│  │             │  │  Service    │  │  Storage    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│                   INFRASTRUCTURE LAYER                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  File I/O   │  │   Crypto    │  │  Platform   │        │
│  │   System    │  │  Providers  │  │  Services   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### Dependency Direction
All dependencies flow **downward and inward**:
- Presentation → Service → Infrastructure
- Outer layers depend on inner layers, never the reverse
- Interfaces define contracts between layers
- Dependency Injection pattern for loose coupling

## SOLID Principles Implementation

### Single Responsibility Principle (SRP)
- Each class has one reason to change
- **Example**: `GF256` handles only field arithmetic, `PolynomialGenerator` only polynomial operations
- File size limitation (450 lines) enforces this principle

### Open/Closed Principle (OCP)
- Open for extension, closed for modification
- **Example**: `IPinCryptoProvider` interface allows different hashing implementations
- Strategy pattern used for extensible cryptographic providers

### Liskov Substitution Principle (LSP)
- Subtypes must be substitutable for base types
- **Example**: `Pbkdf2CryptoProvider` implements `IPinCryptoProvider` contract exactly
- All implementations honor interface contracts

### Interface Segregation Principle (ISP)
- Clients depend only on interfaces they use
- **Example**: Separate interfaces for `IPinStorageRepository` and `IPinCryptoProvider`
- Focused interfaces with specific responsibilities

### Dependency Inversion Principle (DIP)
- Depend on abstractions, not concretions
- **Example**: `PinServiceImpl` depends on `IPinCryptoProvider` interface
- Constructor injection pattern throughout the application

## Security Architecture

### Air-Gapped Design
- No network connectivity during operation
- All data processing happens locally
- Secure local storage only
- No external API calls or telemetry

### Cryptographic Security
- **Timing Attack Prevention**: Constant-time operations in critical paths
- **Secure Randomness**: Platform-secure random number generation
- **Memory Protection**: Secure deletion and data sanitization
- **Hash Security**: PBKDF2 with device-calibrated iterations

### Data Protection
- **PIN Security**: PBKDF2-HMAC-SHA256 with salt
- **Storage Encryption**: XOR encryption for stored data
- **Share Integrity**: Checksums for share validation
- **Secure Deletion**: Multiple overwrites before file deletion

## Performance Characteristics

### Cryptographic Performance
- **GF256 Operations**: O(1) constant time via lookup tables
- **Polynomial Evaluation**: O(n) where n is degree
- **Secret Reconstruction**: O(t²) where t is threshold
- **PBKDF2 Calibration**: Device-optimized iteration counts

### Memory Management
- **Minimal Allocations**: Reuse of typed arrays where possible
- **Secure Cleanup**: Explicit zeroing of sensitive data
- **Memory Bounds**: Predictable memory usage patterns
- **Peak Usage**: < 200MB during normal operations

### Response Time Targets
- **Cold Start**: < 3 seconds
- **UI Interactions**: < 100ms response time
- **PIN Verification**: 100-500ms (calibrated per device)
- **Share Generation**: < 1 second for typical secrets

## Scalability and Maintainability

### Code Organization
- Domain maps document all classes and contracts
- Explicit dependency declarations
- Comprehensive test coverage requirements
- Automated quality gates

### Evolution Strategy
- Interface-based design allows implementation changes
- Domain boundaries prevent cross-cutting changes
- Version-controlled domain maps track architectural evolution
- Security audit integration points

### Technical Debt Management
- 450-line file limit prevents code bloat
- Automated refactoring triggers
- Dependency analysis and cleanup
- Regular security reviews

## Integration Patterns

### Domain Integration
- **Event-driven**: Minimal coupling between domains
- **Interface-based**: Clean contracts between layers
- **Provider Pattern**: State management across domain boundaries
- **Repository Pattern**: Data access abstraction

### Testing Integration
- **Unit Tests**: 100% coverage requirement
- **Integration Tests**: Critical path validation
- **Golden Tests**: UI consistency verification
- **Security Tests**: Cryptographic operation validation

This architecture ensures SRSecrets delivers enterprise-grade security while maintaining code quality, performance, and maintainability standards appropriate for cryptographic applications handling sensitive user data.