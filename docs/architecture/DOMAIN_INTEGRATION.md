# Domain Integration Guide

## Overview

This document describes how the three domains (Crypto, Auth, Presentation) integrate within the SRSecrets application, focusing on communication patterns, dependency management, and state synchronization.

## Domain Boundaries and Communication

### Domain Interaction Map

```
                    ┌─────────────────────────┐
                    │   PRESENTATION DOMAIN   │
                    │                         │
                    │  ┌─────────────────┐   │
                    │  │  AuthProvider   │   │
                    │  └─────────────────┘   │
                    │           │             │
                    │  ┌─────────────────┐   │
                    │  │ SecretProvider  │   │
                    │  └─────────────────┘   │
                    └─────────┬───────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
    ┌─────────▼──────────┐   │    ┌─────────▼──────────┐
    │   AUTH DOMAIN      │   │    │   CRYPTO DOMAIN    │
    │                    │   │    │                    │
    │ ┌─────────────┐   │   │    │ ┌─────────────┐    │
    │ │ PinService  │   │   │    │ │   Shamir    │    │
    │ │    Impl     │   │   │    │ │   Secret    │    │
    │ └─────────────┘   │   │    │ │  Sharing    │    │
    │                    │   │    │ └─────────────┘    │
    │ ┌─────────────┐   │   │    │                    │
    │ │   Secure    │   │   │    │ ┌─────────────┐    │
    │ │  Storage    │   │   │    │ │    Share    │    │
    │ │ Repository  │   │   │    │ │  Generator  │    │
    │ └─────────────┘   │   │    │ └─────────────┘    │
    └────────────────────┘   │    └────────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │ INFRASTRUCTURE     │
                    │                    │
                    │ • File System      │
                    │ • Crypto Providers │
                    │ • Platform Services│
                    └────────────────────┘
```

## Cross-Domain Communication Patterns

### 1. Presentation → Auth Domain

**Pattern**: Provider Pattern with Service Injection

```dart
// AuthProvider coordinates authentication state
class AuthProvider extends ChangeNotifier {
  final IPinService _pinService;
  
  AuthProvider(this._pinService);
  
  // Delegates to auth domain service
  Future<bool> authenticate(String pin) async {
    final result = await _pinService.authenticate(pin);
    // Update UI state based on domain result
    notifyListeners();
    return result.success;
  }
}

// Dependency injection in main.dart
Provider<AuthProvider>(
  create: (context) => AuthProvider(
    PinServiceImpl(
      cryptoProvider: Pbkdf2CryptoProvider(),
      storageRepository: SecureStorageRepository(),
    ),
  ),
)
```

**Communication Flow**:
1. User interacts with PIN input widget
2. `AuthProvider` receives PIN from UI
3. `AuthProvider` delegates to `PinServiceImpl` 
4. `PinServiceImpl` coordinates auth domain logic
5. Result flows back to UI via `ChangeNotifier`

### 2. Presentation → Crypto Domain

**Pattern**: Direct Service Integration with Provider Wrapping

```dart
// SecretProvider manages crypto operations
class SecretProvider extends ChangeNotifier {
  final ShamirSecretSharing _shamir;
  
  SecretProvider() : _shamir = ShamirSecretSharing();
  
  // Direct crypto domain interaction
  Future<bool> createSecret(String secret, int threshold, int shares) async {
    try {
      final result = await _shamir.splitString(secret, threshold, shares);
      _lastResult = result;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
```

**Communication Flow**:
1. User submits secret creation form
2. `SecretProvider` validates input
3. Direct call to `ShamirSecretSharing` facade
4. Crypto domain processes secret splitting
5. Results stored in provider state
6. UI updates via `ChangeNotifier`

### 3. Auth ↔ Crypto Domain Isolation

**Key Principle**: Domains do not directly communicate

The Auth and Crypto domains remain completely isolated:
- No direct imports between domains
- No shared mutable state
- Communication only through Presentation layer coordination

```dart
// CORRECT: Presentation coordinates both domains
class SecretCreationFlow {
  Future<void> createSecretWithAuth(String pin, String secret) async {
    // Step 1: Authenticate via Auth domain
    final authSuccess = await _authProvider.authenticate(pin);
    
    if (authSuccess) {
      // Step 2: Create secret via Crypto domain  
      await _secretProvider.createSecret(secret, threshold, shares);
    }
  }
}

// INCORRECT: Direct domain communication (violation)
class PinServiceImpl {
  // ❌ Should never directly use crypto domain
  final ShamirSecretSharing _shamir; // DOMAIN BOUNDARY VIOLATION
}
```

## State Management Integration

### Provider Architecture

```dart
// Root provider setup coordinates all domains
MultiProvider(
  providers: [
    // Auth domain state
    ChangeNotifierProvider<AuthProvider>(
      create: (context) => AuthProvider(
        PinServiceImpl(
          cryptoProvider: Pbkdf2CryptoProvider(),
          storageRepository: SecureStorageRepository(),
        ),
      ),
    ),
    
    // Crypto domain state
    ChangeNotifierProvider<SecretProvider>(
      create: (context) => SecretProvider(),
    ),
  ],
  child: SRSecretsApp(),
)
```

### State Synchronization Patterns

**1. Authentication State Flow**

```dart
// Authentication state affects entire app
class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isPinSet = false;
  
  // State changes cascade through app
  bool get isAuthenticated => _isAuthenticated;
  bool get isPinSet => _isPinSet;
  
  Future<void> checkAuthStatus() async {
    _isPinSet = await _pinService.isPinSet();
    _isAuthenticated = false; // Always start logged out
    notifyListeners();
  }
}

// Screens react to authentication state
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (!auth.isAuthenticated) {
          return PinLoginScreen();
        }
        return MainTabView();
      },
    );
  }
}
```

**2. Operation State Management**

```dart
// SecretProvider manages operation lifecycle
class SecretProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  MultiSplitResult? _lastResult;
  
  // Clear state between operations
  void clearResults() {
    _lastResult = null;
    _error = null;
    notifyListeners();
  }
  
  // Operation state flows to UI
  bool get hasResults => _lastResult != null;
  String? get error => _error;
}
```

## Dependency Injection Strategy

### Service Layer Configuration

```dart
// Explicit dependency graph construction
class ServiceContainer {
  static IPinService createPinService() {
    return PinServiceImpl(
      cryptoProvider: Pbkdf2CryptoProvider(),
      storageRepository: SecureStorageRepository(),
    );
  }
  
  static ShamirSecretSharing createShamirService() {
    return ShamirSecretSharing();
  }
}

// Provider injection points
class AppProviders {
  static List<SingleChildWidget> get providers => [
    ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(ServiceContainer.createPinService()),
    ),
    ChangeNotifierProvider<SecretProvider>(
      create: (_) => SecretProvider(),
    ),
  ];
}
```

### Interface-Based Dependencies

```dart
// Auth domain defines clear contracts
abstract class IPinService {
  Future<bool> isPinSet();
  Future<PinHash> setPin(String pin);
  Future<PinAuthResult> authenticate(String pin);
}

abstract class IPinCryptoProvider {
  Future<PinHash> hashPin(String pin, {int? iterations});
  Future<bool> verifyPin(String pin, PinHash storedHash);
}

// Implementation injection allows flexibility
class PinServiceImpl implements IPinService {
  final IPinCryptoProvider _cryptoProvider;
  final IPinStorageRepository _storageRepository;
  
  PinServiceImpl({
    required IPinCryptoProvider cryptoProvider,
    required IPinStorageRepository storageRepository,
  }) : _cryptoProvider = cryptoProvider,
       _storageRepository = storageRepository;
}
```

## Error Handling Integration

### Domain-Specific Error Types

```dart
// Auth domain errors
abstract class AuthException implements Exception {
  String get message;
}

class PinValidationException extends AuthException {
  final String message;
  PinValidationException(this.message);
}

class AccountLockedException extends AuthException {
  final Duration remainingLockout;
  AccountLockedException(this.remainingLockout);
  
  @override
  String get message => 'Account locked for ${remainingLockout.inMinutes} minutes';
}

// Crypto domain errors
abstract class CryptoException implements Exception {
  String get message;
}

class InsufficientSharesException extends CryptoException {
  final int provided;
  final int required;
  
  InsufficientSharesException(this.provided, this.required);
  
  @override
  String get message => 'Need $required shares, only $provided provided';
}
```

### Error Propagation Pattern

```dart
// Provider layer handles and translates errors
class AuthProvider extends ChangeNotifier {
  String? _error;
  
  Future<bool> authenticate(String pin) async {
    try {
      final result = await _pinService.authenticate(pin);
      
      if (result.success) {
        _isAuthenticated = true;
        _error = null;
      } else {
        _error = _translateAuthError(result);
      }
      
      notifyListeners();
      return result.success;
      
    } on AccountLockedException catch (e) {
      _error = 'Account locked: ${e.message}';
      notifyListeners();
      return false;
      
    } on PinValidationException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
      
    } catch (e) {
      _error = 'Authentication failed';
      notifyListeners();
      return false;
    }
  }
}

// UI displays translated errors
class PinLoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return Column(
          children: [
            if (auth.error != null)
              ErrorDisplayWidget(message: auth.error!),
            PinInputWidget(
              onPinComplete: auth.authenticate,
            ),
          ],
        );
      },
    );
  }
}
```

## Data Flow Patterns

### Unidirectional Data Flow

```
User Input → Provider → Domain Service → Data Layer → Provider → UI Update
    ↑                                                              ↓
    └─────────────────── Error Feedback ←──────────────────────────┘
```

### Example: Secret Creation Flow

```dart
// 1. User input captured
class CreateSecretScreen extends StatefulWidget {
  void _createSecret() {
    final provider = context.read<SecretProvider>();
    provider.createSecret(
      secretName: _nameController.text,
      secret: _secretController.text,
      threshold: _threshold,
      totalShares: _totalShares,
    );
  }
}

// 2. Provider coordinates operation
class SecretProvider extends ChangeNotifier {
  Future<bool> createSecret(String name, String secret, int threshold, int shares) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // 3. Domain service processes request
      final result = await _shamir.splitString(secret, threshold, shares);
      
      // 4. Store result and update state
      _lastResult = result;
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

// 5. UI reacts to state changes
class CreateSecretScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SecretProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return LoadingIndicator();
        }
        
        if (provider.hasResults) {
          return ShareDistributionScreen();
        }
        
        return SecretInputForm();
      },
    );
  }
}
```

## Integration Testing Strategy

### Cross-Domain Integration Tests

```dart
// Test complete user workflows across domains
class IntegrationTest extends FlutterTest {
  testWidgets('Complete secret sharing workflow', (tester) async {
    await tester.pumpWidget(createTestApp());
    
    // 1. Test authentication integration
    await tester.enterText(find.byType(PinInputWidget), '1234');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    
    // 2. Verify auth state propagation
    expect(find.byType(HomeScreen), findsOneWidget);
    
    // 3. Test crypto operation integration
    await tester.tap(find.text('Create Secret'));
    await tester.enterText(find.byKey(Key('secret-input')), 'test secret');
    await tester.tap(find.text('Split Secret'));
    await tester.pumpAndSettle();
    
    // 4. Verify cross-domain coordination
    expect(find.byType(ShareDistributionScreen), findsOneWidget);
  });
}
```

## Best Practices for Domain Integration

### 1. Maintain Clear Boundaries
- Never import classes directly between Auth and Crypto domains
- Use interfaces to define contracts between layers
- Presentation layer acts as the integration coordinator

### 2. Error Handling Strategy
- Domain-specific exception types
- Translation at provider boundaries
- Consistent error presentation in UI

### 3. State Synchronization
- Single source of truth per domain
- Provider pattern for state management
- Reactive UI updates via ChangeNotifier

### 4. Testing Integration
- Unit tests for individual domain components
- Integration tests for cross-domain workflows
- Provider testing for state management logic

### 5. Performance Considerations
- Lazy initialization of heavy services
- Efficient state change notifications
- Minimal cross-provider dependencies

This integration architecture ensures clean separation of concerns while enabling seamless user experiences across the entire application.