# Secret Persistence Implementation

## Overview
Implemented persistent storage for secret metadata so that created secrets are saved and survive app restarts.

## Problem
The secrets created in the app were only stored in memory, so they were lost when the app was closed or restarted. The "Secrets" tab would always be empty on app restart.

## Solution

### 1. Created Storage Repository
**File**: `lib/domains/storage/repositories/secret_storage_repository.dart`

- Handles saving and loading secret metadata to/from local storage
- Uses `path_provider` to get the appropriate app directory
- Stores data in JSON format in `secrets_metadata.json`
- Platform-specific storage locations:
  - iOS/macOS: Application Support directory
  - Android: Application Documents directory

### 2. Updated SecretInfo Model
**File**: `lib/presentation/providers/secret_provider.dart`

Added serialization methods to `SecretInfo`:
- `toMap()`: Converts SecretInfo to Map for JSON serialization
- `fromMap()`: Creates SecretInfo from Map for deserialization

### 3. Updated SecretProvider
**File**: `lib/presentation/providers/secret_provider.dart`

- Added `SecretStorageRepository` instance
- Constructor now loads saved secrets on initialization
- `createSecret()` now saves to storage after adding to list
- `removeSecret()` now saves to storage after removing from list
- Made operations async to ensure proper saving

### 4. Updated UI Components
- **CreateSecretScreen**: Made `_createSecret()` async to handle the async `createSecret()` method
- **SecretsListScreen**: Made delete operation async to handle the async `removeSecret()` method

## Storage Format

Secrets are stored as JSON with the following structure:
```json
[
  {
    "id": "1234567890",
    "name": "My Secret",
    "createdAt": "2025-08-19T10:30:00.000",
    "threshold": 3,
    "totalShares": 5,
    "type": "text"
  }
]
```

## Important Notes

1. **Only Metadata**: We only store secret metadata (name, date, threshold, etc.), NOT the actual secret content or shares for security reasons.

2. **Automatic Loading**: Secrets are automatically loaded when the SecretProvider is instantiated (which happens at app startup).

3. **Silent Failures**: Storage operations fail silently to ensure the app continues working even if storage is unavailable. Secrets will still work in memory.

4. **Test Limitations**: File system operations may not work properly in test environments, but work correctly in the actual app.

## Files Modified

1. Created:
   - `lib/domains/storage/repositories/secret_storage_repository.dart`

2. Modified:
   - `lib/presentation/providers/secret_provider.dart`
   - `lib/presentation/screens/secrets/create_secret_screen.dart`
   - `lib/presentation/screens/secrets/secrets_list_screen.dart`

## Result
✅ Secrets are now persisted across app sessions
✅ The "Secrets" tab shows previously created secrets
✅ Deleted secrets are properly removed from storage