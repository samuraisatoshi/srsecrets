# SRSecrets Development Guardrails

## Project Overview

This document establishes the development guardrails and architectural principles for the SRSecrets Flutter application implementing Shamir's Shared Secret algorithm.

## Architectural Principles

### 1. Domain Driven Development (DDD)

The project follows Domain Driven Development principles with clear domain boundaries:

- **Core Domain**: Cryptographic operations and secret sharing
- **Supporting Domains**: User interface, data persistence, security
- **Generic Domains**: Utilities, logging, configuration

### 2. SOLID Principles

All code must adhere to SOLID principles:

- **S - Single Responsibility**: Each class has one reason to change
- **O - Open/Closed**: Open for extension, closed for modification
- **L - Liskov Substitution**: Subtypes must be substitutable for base types
- **I - Interface Segregation**: Clients shouldn't depend on interfaces they don't use
- **D - Dependency Inversion**: Depend on abstractions, not concretions

## Code Quality Standards

### File Size Limitation
- **Maximum 450 lines per file**: No single file may exceed 450 lines
- If a file approaches this limit, it must be refactored into smaller, focused components

### Testing Requirements
- **100% Test Coverage**: Every class and method must have corresponding unit tests
- **Test-Driven Development**: Write tests before implementation when possible
- **Integration Tests**: Critical paths must have integration test coverage
- **Security Tests**: All cryptographic operations must have security-focused tests

### Documentation Standards

#### Domain Maps
Each domain must maintain a `map.json` file containing:

```json
{
  "domain_name": "string",
  "purpose": "string", 
  "classes": [
    {
      "class_name": "string",
      "purpose": "string",
      "methods": [
        {
          "method_name": "string",
          "purpose": "string",
          "contract": {
            "inputs": [],
            "outputs": [],
            "preconditions": [],
            "postconditions": []
          },
          "dependencies": []
        }
      ],
      "dependencies": []
    }
  ]
}
```

#### Root Domain Registry
The project root must contain `domain_maps.json`:

```json
{
  "domains": [
    {
      "name": "string",
      "purpose": "string", 
      "map_path": "relative/path/to/map.json"
    }
  ]
}
```

## Security Guidelines

### Cryptographic Standards
- Use only well-established cryptographic libraries
- Implement proper key derivation functions
- Ensure secure random number generation
- Never log or expose sensitive data

### Data Protection
- All sensitive data must be encrypted at rest
- Use secure memory handling practices
- Implement proper data sanitization
- PIN-based access control for all operations

### Air-Gapped Design
- No network connectivity allowed
- All data remains local to the device
- No external dependencies during runtime
- Secure local storage only

## Flutter-Specific Guidelines

### Project Structure
```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── security/
├── domains/
│   ├── crypto/
│   ├── storage/
│   ├── auth/
│   └── ui/
└── main.dart
```

### State Management
- Use provider pattern or similar for state management
- Maintain clear separation between business logic and UI
- Implement proper error handling and recovery

### UI/UX Requirements
- Material Design 3 compliance
- Accessibility standards (WCAG 2.1 AA)
- Responsive design for various screen sizes
- Dark/Light theme support

## Development Workflow

### Code Review Requirements
- All code must pass automated tests
- Security review for cryptographic components
- Performance review for critical paths
- Documentation review for API contracts

### Commit Standards
- Conventional commit messages
- Atomic commits with single responsibility
- Signed commits for security
- No sensitive data in commit history

### Branch Strategy
- Feature branches for new functionality
- Hotfix branches for critical security issues
- Main branch always in deployable state
- Regular security audits of codebase

## Dependencies Management

### Allowed Dependencies
- Only security-audited Flutter packages
- Minimal external dependencies
- Regular dependency updates for security patches
- No packages with network capabilities

### Prohibited Dependencies
- Any package requiring network access
- Analytics or telemetry packages
- Packages with known security vulnerabilities
- Unmaintained or deprecated packages

## Performance Standards

### App Performance
- Cold start time < 3 seconds
- UI interactions < 100ms response
- Memory usage < 200MB peak
- Battery efficient cryptographic operations

### Security Performance
- Key derivation within acceptable time limits
- Secure memory cleanup
- Minimal attack surface
- Regular security benchmarking

## Compliance and Auditing

### Security Audits
- Regular third-party security audits
- Penetration testing of implemented features
- Code review by cryptography experts
- Vulnerability assessment and mitigation

### Documentation Audits
- Regular review of domain maps
- API contract validation
- Test coverage verification
- Architecture decision records

---

**Remember**: These guardrails are mandatory. Any deviation requires explicit documentation and justification. Security and code quality are non-negotiable aspects of this project.