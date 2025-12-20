# Privacy Policy

**SRSecrets - Shamir Secret Sharing**

*Last updated: December 19, 2024*

---

## Overview

SRSecrets ("the App") is a security-focused application designed to split and reconstruct secrets using Shamir's Secret Sharing algorithm. This privacy policy explains how we handle your data.

**TL;DR: We collect nothing. Your data never leaves your device.**

---

## Data Collection

### What We DO NOT Collect

- **Personal Information**: We do not collect names, emails, phone numbers, or any identifying information.
- **Usage Data**: We do not track how you use the app.
- **Analytics**: We do not use any analytics services (Google Analytics, Firebase, etc.).
- **Crash Reports**: We do not collect crash reports or diagnostics.
- **Location Data**: We do not access your location.
- **Network Data**: The app has no internet permissions and cannot transmit data.

### What We DO Store (Locally Only)

The following data is stored **exclusively on your device**:

| Data | Storage Location | Purpose |
|------|------------------|---------|
| PIN Hash | Android Keystore (hardware-backed) | Authentication |
| Authentication Attempts | Local encrypted file | Brute-force protection |
| App Settings | SharedPreferences | User preferences |

**Important**: Your actual secrets (seeds, passwords, keys) are NOT stored by the app. They are split into shares that you distribute manually.

---

## Data Security

### Encryption

- **PIN Storage**: PBKDF2-HMAC-SHA256 with 100,000+ iterations
- **Local Files**: Encrypted using platform keychain
- **Hardware Security**: Android Keystore with TEE/StrongBox when available

### Secure Deletion

When you delete data, we perform:
1. Three passes of random data overwrite
2. One pass of zero overwrite
3. File deletion

---

## Data Sharing

**We do not share any data with anyone because we do not have access to any data.**

- No third-party services
- No advertising networks
- No analytics providers
- No cloud storage
- No servers

---

## Air-Gapped Operation

SRSecrets is designed to operate **completely offline**:

- The app requests no internet permissions
- No network calls are made
- No data is transmitted
- Works in airplane mode

---

## Children's Privacy

The app does not knowingly collect any information from anyone, including children under 13 years of age.

---

## Changes to This Policy

We may update this Privacy Policy from time to time. Changes will be posted on this page with an updated revision date.

---

## Open Source

SRSecrets is open source. You can verify our privacy claims by reviewing the source code:

**GitHub**: https://github.com/samuraisatoshi/srsecrets

---

## Contact

If you have questions about this Privacy Policy:

- **GitHub Issues**: https://github.com/samuraisatoshi/srsecrets/issues

---

## Your Rights

Since we don't collect any data:
- There is no data to access
- There is no data to delete
- There is no data to export
- There is no data to correct

**Your secrets remain yours, and yours alone.**

---

*This app was created with privacy as a fundamental design principle, not an afterthought.*
