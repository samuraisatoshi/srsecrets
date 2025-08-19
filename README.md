# SRSecrets - Secure Air-Gapped Cryptographic Secret Management

## Project Overview

SRSecrets is a cross-platform Flutter mobile application implementing Shamir's Secret Sharing algorithm for secure, distributed management of cryptographic secrets. Built following Domain-Driven Design (DDD) principles and SOLID architecture, this air-gapped application provides enterprise-grade security for sensitive data management without network dependencies.

## Project Scope

### Core Domains

1. **Cryptographic Domain (`lib/domains/crypto/`)**
   - Complete Shamir's Secret Sharing implementation using GF(256) finite field arithmetic
   - Secure polynomial generation and evaluation with constant-time operations
   - Multi-byte secret splitting and reconstruction capabilities
   - Cryptographically secure random number generation
   - Share serialization with integrity verification

2. **Authentication Domain (`lib/domains/auth/`)**
   - PIN-based authentication with PBKDF2-HMAC-SHA256 hashing
   - Progressive lockout protection with configurable attempt limits
   - Air-gapped secure storage with XOR encryption and secure deletion
   - Timing attack resistance and security parameter calibration
   - Authentication attempt history tracking

3. **Presentation Domain (`lib/presentation/`)**
   - Material Design 3 UI with light/dark theme support
   - State management using Provider pattern
   - PIN setup and authentication flows
   - Secret creation and reconstruction interfaces
   - Secure share distribution with clipboard integration

### Technical Architecture

**Design Patterns:**
- Domain-Driven Development (DDD) with clear bounded contexts
- SOLID principles enforcement across all layers
- Repository pattern for data persistence
- Provider pattern for state management
- Factory pattern for cryptographic component creation

**Security Features:**
- Complete air-gapped operation (no network access)
- PBKDF2 key derivation with device-calibrated iterations
- Constant-time cryptographic operations
- Secure memory handling and data sanitization
- PIN-based access control with lockout protection
- Local encrypted storage with secure deletion

**Quality Standards:**
- Maximum 450 lines per file enforced
- 100% unit test coverage requirement
- Comprehensive domain mapping documentation
- Security-focused code reviews
- Performance benchmarking for cryptographic operations

### Key Capabilities

**Secret Management:**
- Split any UTF-8 string or binary data using configurable threshold schemes
- Support for 2-255 shares with customizable reconstruction thresholds
- Secure share distribution with participant packaging
- Real-time secret reconstruction from collected shares
- Local secret history with metadata tracking

**User Experience:**
- Intuitive PIN setup with confirmation flow
- Visual share creation and distribution interface
- Step-by-step secret reconstruction process
- Help documentation and security guidance
- Responsive design for various screen sizes

**Enterprise Security:**
- Mathematically proven secret sharing algorithm
- No single point of failure in secret storage
- Configurable security parameters per device performance
- Comprehensive audit trail of authentication attempts
- Secure cleanup of sensitive data in memory

### Compliance and Standards

- Follows cryptographic best practices (NIST guidelines)
- Implements defense-in-depth security architecture
- Maintains detailed architectural decision records
- Provides comprehensive security documentation
- Supports security auditing and penetration testing

## Information Security Importance

### The Challenge of Secret Management

In the digital age, managing sensitive information like cryptocurrency private keys, passwords, and other secrets presents significant security challenges:

1. **Single Point of Failure**: Traditional storage methods create vulnerabilities where losing access to one location means losing everything
2. **Trust Distribution**: Relying on a single person or entity to safeguard critical secrets is inherently risky
3. **Accessibility vs Security**: Balancing easy access for legitimate users while preventing unauthorized access

### Shamir's Secret Sharing Solution

Shamir's Secret Sharing algorithm provides an elegant solution by:

- **Eliminating single points of failure** through distributed storage
- **Requiring consensus** for secret reconstruction (threshold-based security)
- **Maintaining perfect secrecy** - individual shares reveal no information about the original secret
- **Providing flexible security models** with customizable threshold requirements

### Security Features

- **Air-gapped operation**: No internet connectivity required or allowed
- **Local data storage**: All data remains on the device
- **PIN-based access control**: Additional layer of authentication
- **Cryptographic security**: Built on mathematically proven algorithms
- **Cross-platform compatibility**: Consistent security across iOS and Android

## Key Benefits

1. **Distributed Trust**: No single person or location holds complete access
2. **Fault Tolerance**: System remains functional even if some shares are lost
3. **Flexible Thresholds**: Configure how many shares are needed for reconstruction
4. **Privacy-First Design**: No data transmission, no cloud dependencies
5. **User-Controlled Security**: Users maintain complete control over their data

## Use Cases

- Cryptocurrency wallet backup and recovery
- Secure storage of master passwords
- Protection of sensitive documents
- Multi-party authentication scenarios
- Emergency access planning for digital assets

## Security Principles

This application is built with security as the foundation:

- **Defense in Depth**: Multiple layers of security controls
- **Principle of Least Privilege**: Minimal permissions and access rights
- **Data Minimization**: Only essential data is stored
- **Transparent Operation**: Clear understanding of all security operations
- **Regular Security Reviews**: Continuous evaluation of security measures

---

**Important**: This application is designed for users who understand the importance of information security and are committed to following best practices for secret management. Proper understanding of the Shamir's Secret Sharing algorithm and its implications is essential for safe usage.
