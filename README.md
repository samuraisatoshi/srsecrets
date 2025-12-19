# SRSecrets

**Secure Secret Sharing for the Privacy-Conscious**

SRSecrets is an air-gapped mobile application that implements Shamir's Secret Sharing algorithm to securely split and reconstruct sensitive data. Built with Flutter following Domain-Driven Design (DDD) and SOLID principles.

---

## Table of Contents

- [Why SRSecrets?](#why-srsecrets)
- [How It Works](#how-it-works)
- [Privacy & Security](#privacy--security)
- [Getting Started](#getting-started)
- [Usage Examples](#usage-examples)
- [Architecture](#architecture)
- [Technical References](#technical-references)
- [License](#license)
- [Support the Project](#support-the-project)

---

## Why SRSecrets?

Traditional secret storage creates dangerous single points of failure:

| Problem | Risk |
|---------|------|
| Password in a safe | Fire, theft, or forgotten combination = total loss |
| Seed phrase on paper | Physical damage or discovery = compromised funds |
| Trusted person | Relationship changes, death, or betrayal = vulnerability |

**SRSecrets solves this** by mathematically splitting your secret into multiple shares where:
- No single share reveals ANY information about the original secret
- You choose how many shares are needed to reconstruct (e.g., 3 of 5)
- Shares can be distributed across locations, people, and storage methods

---

## How It Works

### Shamir's Secret Sharing Algorithm

SRSecrets uses **Shamir's Secret Sharing** (SSS), a cryptographic algorithm invented by Adi Shamir in 1979. It provides **information-theoretic security**, meaning it's mathematically impossible to derive any information about the secret from fewer shares than the threshold.

```
Original Secret: "my-crypto-seed-phrase"
                         |
                         v
            ┌────────────┴────────────┐
            │   Polynomial Generation  │
            │   over GF(256) Field     │
            └────────────┬────────────┘
                         |
        ┌────────┬───────┼───────┬────────┐
        v        v       v       v        v
     Share 1  Share 2  Share 3  Share 4  Share 5
     (Safe)   (Family) (Bank)   (Cloud)  (Friend)

    Reconstruction: Any 3 shares → Original Secret
```

### The Mathematics

- **Finite Field Arithmetic**: Operations in GF(256) ensure shares are the same size as the secret
- **Polynomial Interpolation**: Lagrange interpolation reconstructs the secret from threshold shares
- **Perfect Secrecy**: k-1 shares provide zero information about the secret (where k = threshold)

---

## Privacy & Security

### Air-Gapped by Design

SRSecrets operates **completely offline**:

- **No network permissions** - The app cannot access the internet
- **No cloud sync** - All data stays on your device
- **No analytics** - Zero telemetry or tracking
- **No third-party services** - Everything runs locally

### Security Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    USER INTERFACE                        │
├─────────────────────────────────────────────────────────┤
│                 PIN AUTHENTICATION                       │
│  • PBKDF2-HMAC-SHA256 (100,000+ iterations)             │
│  • Progressive lockout (exponential backoff)            │
│  • Timing-attack resistant comparison                   │
├─────────────────────────────────────────────────────────┤
│              CRYPTOGRAPHIC ENGINE                        │
│  • Shamir's Secret Sharing over GF(256)                 │
│  • Cryptographically Secure PRNG (platform native)      │
│  • Constant-time polynomial operations                  │
├─────────────────────────────────────────────────────────┤
│                SECURE STORAGE                            │
│  • XOR encryption with derived keys                     │
│  • Secure file deletion (multi-pass overwrite)          │
│  • Platform keychain integration                        │
└─────────────────────────────────────────────────────────┘
```

### What We Protect Against

| Threat | Protection |
|--------|------------|
| Device theft | PIN authentication with lockout |
| Brute force attacks | PBKDF2 key stretching + progressive delays |
| Memory inspection | Secure memory clearing after use |
| File recovery | Multi-pass secure deletion |
| Side-channel attacks | Constant-time cryptographic operations |
| Single point of failure | Threshold-based secret sharing |

### What You Must Protect

- **Your PIN** - Never share it, never write it with your shares
- **Threshold shares** - Store them in genuinely separate locations
- **Share integrity** - Verify shares are complete before distribution

---

## Getting Started

### Installation

```bash
# Clone the repository
git clone https://github.com/samuraisatoshi/srsecrets.git
cd srsecrets

# Install dependencies
flutter pub get

# Run on device (recommended for security)
flutter run --release
```

### First Launch

1. **Complete onboarding** - Learn about Shamir's Secret Sharing
2. **Set up your PIN** - Choose a strong 4-8 digit PIN
3. **You're ready** - Start splitting secrets securely

---

## Usage Examples

### Example 1: Cryptocurrency Seed Phrase Backup

**Scenario**: Protect a 24-word recovery phrase for a Bitcoin wallet.

**Configuration**:
- Total shares: **5**
- Threshold: **3** (any 3 shares can recover)

**Distribution Strategy**:
| Share | Location | Rationale |
|-------|----------|-----------|
| 1 | Home safe | Immediate access |
| 2 | Bank safety deposit | Fire/flood protection |
| 3 | Trusted family member | Geographic distribution |
| 4 | Attorney's office | Legal succession |
| 5 | Encrypted cloud backup | Redundancy |

**Recovery**: If your home burns down, you still have shares 2, 3, 4, and 5. Any three reconstruct your seed phrase.

---

### Example 2: Password Manager Master Password

**Scenario**: Backup the master password for your password manager.

**Configuration**:
- Total shares: **3**
- Threshold: **2**

**Distribution**:
| Share | Location |
|-------|----------|
| 1 | Personal encrypted USB |
| 2 | Spouse/partner |
| 3 | Sealed envelope with parents |

**Benefit**: If you're incapacitated, your spouse and parents together can access your accounts.

---

### Example 3: Business Encryption Keys

**Scenario**: Protect SSL certificate private keys for a startup.

**Configuration**:
- Total shares: **5**
- Threshold: **3**

**Distribution**:
| Share | Holder |
|-------|--------|
| 1 | CEO |
| 2 | CTO |
| 3 | Lead Developer |
| 4 | External Legal Counsel |
| 5 | Hardware Security Module |

**Benefit**: No single employee can compromise certificates. Company survives any two people leaving.

---

### Example 4: Digital Estate Planning

**Scenario**: Ensure heirs can access digital assets after death.

**Configuration**:
- Total shares: **4**
- Threshold: **3**

**Distribution**:
| Share | Holder |
|-------|--------|
| 1 | Estate attorney (with will) |
| 2 | Spouse |
| 3 | Adult child #1 |
| 4 | Adult child #2 |

**Benefit**: Requires family consensus, protected during your lifetime, accessible when needed.

---

## Architecture

### Domain-Driven Design Structure

```
lib/
├── core/                    # Cross-cutting concerns
│   └── routing/             # Navigation logic
│
├── domains/                 # Business logic (zero dependencies)
│   ├── auth/                # Authentication domain
│   │   ├── models/          # PinHash, AuthAttempt
│   │   ├── services/        # PinService, PinValidator
│   │   └── providers/       # PBKDF2CryptoProvider
│   │
│   ├── crypto/              # Cryptographic domain
│   │   ├── shares/          # Share, ShareGenerator
│   │   ├── random/          # SecureRandom
│   │   └── gf256/           # Finite field arithmetic
│   │
│   ├── settings/            # App settings domain
│   └── onboarding/          # User education domain
│
├── infrastructure/          # External implementations
│   └── persistence/         # File storage, encryption
│
└── presentation/            # UI layer
    ├── providers/           # State management
    ├── screens/             # UI screens
    ├── widgets/             # Reusable components
    └── theme/               # Visual styling
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **GF(256) field** | Shares same size as secret, byte-aligned operations |
| **PBKDF2 over Argon2** | Wider platform support, sufficient for PIN protection |
| **Provider pattern** | Simple, testable state management |
| **No external crypto libs** | Full audit control, minimal attack surface |
| **450 line file limit** | Maintainability, single responsibility |

---

## Technical References

### Shamir's Secret Sharing

- **Original Paper**: Shamir, Adi. "How to share a secret." *Communications of the ACM* 22.11 (1979): 612-613.
  - [ACM Digital Library](https://dl.acm.org/doi/10.1145/359168.359176)
- **Wikipedia**: [Shamir's Secret Sharing](https://en.wikipedia.org/wiki/Shamir%27s_secret_sharing)
- **Interactive Explanation**: [Shamir's Secret Sharing Explained Visually](https://www.youtube.com/watch?v=iFY5SyY3IMQ)

### Finite Field Arithmetic (GF(256))

- **Galois Field Theory**: [Finite Field Arithmetic](https://en.wikipedia.org/wiki/Finite_field_arithmetic)
- **GF(256) in AES**: [Rijndael S-box](https://en.wikipedia.org/wiki/Rijndael_S-box)
- **Implementation Guide**: [A Tutorial on Reed-Solomon Coding](https://www.cs.cmu.edu/~guyb/realworld/reedsolomon/reed_solomon_codes.html)

### Cryptographic Random Number Generation

- **CSPRNG Requirements**: [NIST SP 800-90A](https://csrc.nist.gov/publications/detail/sp/800-90a/rev-1/final)
- **Platform Implementations**:
  - iOS: [SecRandomCopyBytes](https://developer.apple.com/documentation/security/1399291-secrandomcopybytes)
  - Android: [SecureRandom](https://developer.android.com/reference/java/security/SecureRandom)
- **Randomness Testing**: [NIST Statistical Test Suite](https://csrc.nist.gov/projects/random-bit-generation/documentation-and-software)

### Key Derivation (PBKDF2)

- **RFC 2898**: [PKCS #5: Password-Based Cryptography Specification](https://tools.ietf.org/html/rfc2898)
- **OWASP Guidelines**: [Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
- **Iteration Count**: [NIST SP 800-132](https://csrc.nist.gov/publications/detail/sp/800-132/final)

### Lagrange Interpolation

- **Mathematical Foundation**: [Lagrange Polynomial](https://en.wikipedia.org/wiki/Lagrange_polynomial)
- **Numerical Methods**: [Polynomial Interpolation](https://mathworld.wolfram.com/LagrangeInterpolatingPolynomial.html)

### Security Best Practices

- **OWASP Mobile Security**: [Mobile Application Security Verification Standard](https://mas.owasp.org/MASVS/)
- **Cryptographic Standards**: [NIST Cryptographic Standards and Guidelines](https://csrc.nist.gov/projects/cryptographic-standards-and-guidelines)

---

## License

This project is licensed under the **PolyForm Noncommercial License 1.0.0**.

**You are free to**:
- Use for personal, educational, and research purposes
- Modify and create derivative works
- Distribute copies for noncommercial purposes

**Commercial use requires prior written approval** from the author.

See [LICENSE](LICENSE) for full terms.

---

## Support the Project

If SRSecrets helps protect your digital assets, consider supporting continued development:

### Cryptocurrency Donations

| Currency | Network | Address |
|----------|---------|---------|
| **USDT** | Liquid Network | `lq1qqtqkchjytn4k09asf97z0ysa2jw5cxecrrzxsaf879epmvdf4hur5aqtqetj98enxmhyer5fwk9vnxn9cgylvjzg5546nas0e` |

### Other Ways to Help

- **Star the repository** - Helps others discover the project
- **Report issues** - Security vulnerabilities or bugs
- **Contribute code** - PRs welcome following our architecture guidelines
- **Spread the word** - Share with others who need secure secret management

---

<p align="center">
  <strong>Your secrets. Your control. Mathematically guaranteed.</strong>
</p>
