# Development Guidelines

## Overview

This document provides comprehensive development guidelines for the SRSecrets Flutter application, covering Flutter-specific architectural patterns, best practices, coding standards, performance optimizations, and deployment configurations.

## Flutter-Specific Architectural Patterns

### State Management Architecture

**Provider Pattern Implementation**:

```dart
// Root application setup with proper provider hierarchy
class SRSecretsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth domain state management
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            pinService: ServiceLocator.get<IPinService>(),
          ),
        ),
        
        // Crypto domain state management  
        ChangeNotifierProvider<SecretProvider>(
          create: (context) => SecretProvider(),
        ),
        
        // Theme state management
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SRSecrets',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: AuthenticationGate(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

// Authentication gate pattern for protected routes
class AuthenticationGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // Handle different authentication states
        if (!auth.isInitialized) {
          return SplashScreen();
        }
        
        if (!auth.isPinSet) {
          return PinSetupScreen();
        }
        
        if (!auth.isAuthenticated) {
          return PinLoginScreen();
        }
        
        return HomeScreen();
      },
    );
  }
}
```

**State Synchronization Patterns**:

```dart
// Reactive state management with proper lifecycle
class SecretProvider extends ChangeNotifier {
  // Private state variables
  bool _isLoading = false;
  String? _error;
  MultiSplitResult? _lastResult;
  List<SecretInfo> _secretHistory = [];
  
  // Public getters with validation
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasResults => _lastResult != null;
  
  List<ParticipantPackage> get distributionPackages {
    if (_lastResult == null) {
      throw StateError('No secret has been split yet');
    }
    return _lastResult!.createDistributionPackages();
  }
  
  // State-changing operations with proper error handling
  Future<bool> createSecret({
    required String secretName,
    required String secret,
    required int threshold,
    required int totalShares,
  }) async {
    // Validate inputs
    if (secretName.trim().isEmpty) {
      _setError('Secret name cannot be empty');
      return false;
    }
    
    if (secret.trim().isEmpty) {
      _setError('Secret cannot be empty');
      return false;
    }
    
    _setLoading(true);
    
    try {
      // Perform crypto operation
      final result = await ShamirSecretSharing().splitString(
        secret,
        threshold,
        totalShares,
      );
      
      // Update state
      _lastResult = result;
      
      // Store secret info for history
      final secretInfo = SecretInfo(
        name: secretName,
        threshold: threshold,
        totalShares: totalShares,
        createdAt: DateTime.now(),
      );
      
      _secretHistory.add(secretInfo);
      await _saveSecretHistory();
      
      _setLoading(false);
      return true;
      
    } catch (e) {
      _setError('Failed to create secret: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  
  // Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  void clearResults() {
    _lastResult = null;
    _error = null;
    notifyListeners();
  }
}
```

### Widget Architecture Patterns

**Stateless Widget Composition**:

```dart
// Compose complex UIs from simple, focused widgets
class CreateSecretScreen extends StatefulWidget {
  @override
  _CreateSecretScreenState createState() => _CreateSecretScreenState();
}

class _CreateSecretScreenState extends State<CreateSecretScreen> {
  final _formKey = GlobalKey<FormState>();
  final _secretController = TextEditingController();
  final _nameController = TextEditingController();
  
  int _threshold = 2;
  int _totalShares = 3;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Secret'),
      ),
      body: Consumer<SecretProvider>(
        builder: (context, secretProvider, child) {
          if (secretProvider.isLoading) {
            return LoadingIndicator(message: 'Splitting secret...');
          }
          
          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Reusable form header component
                SecretFormHeader(
                  title: 'New Secret',
                  subtitle: 'Enter your secret to split into shares',
                ),
                
                // Input fields with validation
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Secret name input
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Secret Name',
                            hintText: 'Enter a memorable name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'Please enter a secret name';
                            }
                            return null;
                          },
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Secret content input
                        TextFormField(
                          controller: _secretController,
                          decoration: InputDecoration(
                            labelText: 'Secret',
                            hintText: 'Enter your secret',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.visibility),
                              onPressed: () {
                                // Toggle secret visibility
                              },
                            ),
                          ),
                          obscureText: true,
                          maxLines: 3,
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'Please enter your secret';
                            }
                            return null;
                          },
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Threshold configuration widget
                        ThresholdConfigWidget(
                          threshold: _threshold,
                          totalShares: _totalShares,
                          onThresholdChanged: (value) {
                            setState(() {
                              _threshold = value;
                            });
                          },
                          onTotalSharesChanged: (value) {
                            setState(() {
                              _totalShares = value;
                              if (_threshold > _totalShares) {
                                _threshold = _totalShares;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Error display
                if (secretProvider.error != null)
                  ErrorDisplayWidget(
                    message: secretProvider.error!,
                    onDismiss: secretProvider.clearError,
                  ),
                
                // Action buttons
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _createSecret,
                            child: Text('Split Secret'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _createSecret() async {
    if (!_formKey.currentState!.validate()) return;
    
    final success = await context.read<SecretProvider>().createSecret(
      secretName: _nameController.text.trim(),
      secret: _secretController.text.trim(),
      threshold: _threshold,
      totalShares: _totalShares,
    );
    
    if (success) {
      // Navigate to share distribution
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ShareDistributionScreen(),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _secretController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
```

**Custom Widget Best Practices**:

```dart
// Reusable custom widgets with proper encapsulation
class PinInputWidget extends StatefulWidget {
  final Function(String) onPinComplete;
  final int pinLength;
  final bool obscureText;
  final String? errorText;
  final bool enabled;
  
  const PinInputWidget({
    Key? key,
    required this.onPinComplete,
    this.pinLength = 4,
    this.obscureText = true,
    this.errorText,
    this.enabled = true,
  }) : super(key: key);
  
  @override
  _PinInputWidgetState createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget>
    with TickerProviderStateMixin {
  String _currentPin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _shakeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final offset = sin(_shakeAnimation.value * pi * 2) * 5;
        
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Column(
            children: [
              // PIN dots display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.pinLength, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _currentPin.length
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                    ),
                    child: widget.obscureText && index < _currentPin.length
                        ? Icon(Icons.circle, size: 8, color: Colors.white)
                        : (index < _currentPin.length
                            ? Text(
                                _currentPin[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null),
                  );
                }),
              ),
              
              SizedBox(height: 16),
              
              // Error text display
              if (widget.errorText != null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    widget.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).errorColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              SizedBox(height: 24),
              
              // Numeric keypad
              _buildNumericKeypad(),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildNumericKeypad() {
    return Container(
      width: 240,
      child: Column(
        children: [
          // Number rows
          for (int row = 0; row < 3; row++)
            Row(
              children: [
                for (int col = 1; col <= 3; col++)
                  Expanded(
                    child: _buildKeypadButton(
                      '${row * 3 + col}',
                      () => _onDigitPressed('${row * 3 + col}'),
                    ),
                  ),
              ],
            ),
          
          // Bottom row: 0, backspace
          Row(
            children: [
              Expanded(child: SizedBox()),
              Expanded(
                child: _buildKeypadButton('0', () => _onDigitPressed('0')),
              ),
              Expanded(
                child: _buildKeypadButton(
                  '⌫',
                  _onBackspacePressed,
                  isIcon: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildKeypadButton(
    String text,
    VoidCallback onPressed, {
    bool isIcon = false,
  }) {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: widget.enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 56,
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: isIcon ? 20 : 24,
                  fontWeight: FontWeight.w500,
                  color: widget.enabled ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _onDigitPressed(String digit) {
    if (_currentPin.length < widget.pinLength) {
      setState(() {
        _currentPin += digit;
      });
      
      // Check if PIN is complete
      if (_currentPin.length == widget.pinLength) {
        widget.onPinComplete(_currentPin);
      }
    }
  }
  
  void _onBackspacePressed() {
    if (_currentPin.isNotEmpty) {
      setState(() {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      });
    }
  }
  
  void showError() {
    _shakeController.forward().then((_) {
      _shakeController.reset();
    });
  }
  
  void clear() {
    setState(() {
      _currentPin = '';
    });
  }
  
  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }
}
```

## Best Practices and Coding Standards

### Code Organization

**File Structure Standards**:

```
lib/
├── core/                         # Cross-cutting concerns
│   ├── constants/               # App-wide constants
│   ├── errors/                  # Custom exception classes
│   ├── utils/                   # Utility functions
│   └── security/                # Security utilities
├── domains/                      # Domain-driven structure
│   ├── auth/                    # Authentication domain
│   │   ├── models/             # Domain models
│   │   ├── services/           # Domain services
│   │   ├── repositories/       # Data access interfaces
│   │   └── providers/          # Infrastructure implementations
│   ├── crypto/                 # Cryptography domain
│   └── storage/                # Data persistence domain
├── presentation/               # UI layer
│   ├── screens/               # Screen widgets
│   ├── widgets/               # Reusable UI components
│   ├── providers/             # State management
│   └── theme/                 # App theming
└── main.dart                  # Application entry point
```

**Import Organization**:

```dart
// Standard Dart imports first
import 'dart:async';
import 'dart:convert';
import 'dart:math';

// Flutter framework imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Third-party package imports (alphabetical)
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

// Local imports (alphabetical, with relative paths)
import '../core/errors/crypto_exceptions.dart';
import '../domains/crypto/models/share.dart';
import '../domains/crypto/services/shamir_secret_sharing.dart';
```

### Naming Conventions

**Class Naming**:
```dart
// Classes: PascalCase
class ShamirSecretSharing { }
class PinInputWidget extends StatefulWidget { }
class SecureStorageRepository implements IStorageRepository { }

// Interfaces: I prefix + PascalCase
abstract class IPinService { }
abstract class ICryptoProvider { }

// Exceptions: descriptive + Exception suffix
class PinValidationException extends Exception { }
class InsufficientSharesException extends CryptoException { }

// Enums: PascalCase
enum AuthenticationStatus { authenticated, unauthenticated, locked }
enum ThemeMode { light, dark, system }
```

**Method and Variable Naming**:
```dart
// Methods: camelCase, descriptive verbs
Future<bool> authenticateUser(String pin) async { }
void clearSensitiveData() { }
List<Share> generateShares(String secret, int threshold, int total) { }

// Variables: camelCase, descriptive nouns
String reconstructedSecret;
bool isAuthenticated;
Duration remainingLockoutTime;

// Constants: SCREAMING_SNAKE_CASE
static const int MAX_PIN_ATTEMPTS = 3;
static const Duration LOCKOUT_DURATION = Duration(minutes: 15);
static const String STORAGE_KEY_PIN_HASH = 'pin_hash';

// Private members: underscore prefix
String _currentPin;
bool _isLoading;
void _handleAuthenticationFailure() { }
```

### Error Handling Patterns

**Comprehensive Error Handling**:

```dart
// Custom exception hierarchy
abstract class SRSecretsException implements Exception {
  final String message;
  final String? details;
  final Object? cause;
  
  const SRSecretsException(this.message, {this.details, this.cause});
  
  @override
  String toString() => 'SRSecretsException: $message${details != null ? ' - $details' : ''}';
}

class AuthenticationException extends SRSecretsException {
  const AuthenticationException(String message, {String? details, Object? cause})
      : super(message, details: details, cause: cause);
}

class CryptographicException extends SRSecretsException {
  const CryptographicException(String message, {String? details, Object? cause})
      : super(message, details: details, cause: cause);
}

// Service layer error handling
class PinServiceImpl implements IPinService {
  @override
  Future<PinAuthResult> authenticate(String pin) async {
    try {
      // Validate input
      if (pin.trim().isEmpty) {
        throw AuthenticationException('PIN cannot be empty');
      }
      
      // Check if account is locked
      final history = await _storageRepository.loadAttemptHistory();
      if (history.isLocked()) {
        final remaining = history.getLockoutRemaining();
        throw AccountLockedException(remaining!);
      }
      
      // Load stored hash
      final storedHash = await _storageRepository.loadPinHash();
      if (storedHash == null) {
        throw AuthenticationException('No PIN configured');
      }
      
      // Verify PIN
      final isValid = await _cryptoProvider.verifyPin(pin, storedHash);
      
      // Record attempt
      history.addAttempt(isValid);
      await _storageRepository.storeAttemptHistory(history);
      
      if (isValid) {
        return PinAuthResult.success();
      } else {
        return PinAuthResult.failure('Invalid PIN');
      }
      
    } on AccountLockedException {
      rethrow; // Pass through specific exceptions
    } on AuthenticationException {
      rethrow;
    } catch (e, stackTrace) {
      // Log unexpected errors
      print('Unexpected authentication error: $e\n$stackTrace');
      throw AuthenticationException(
        'Authentication failed due to system error',
        details: e.toString(),
        cause: e,
      );
    }
  }
}

// UI layer error handling and display
class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;
  
  const ErrorDisplayWidget({
    Key? key,
    required this.message,
    this.onDismiss,
    this.onRetry,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade700,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text('Retry'),
              ),
            if (onDismiss != null)
              IconButton(
                icon: Icon(Icons.close),
                onPressed: onDismiss,
                color: Colors.red.shade700,
              ),
          ],
        ),
      ),
    );
  }
}
```

### Asynchronous Programming Patterns

**Future and Stream Handling**:

```dart
// Proper async/await usage
class SecretProvider extends ChangeNotifier {
  Future<bool> createSecret(String secret, int threshold, int shares) async {
    _setLoading(true);
    
    try {
      // Use async/await for better error handling
      final result = await _shamirService.splitString(secret, threshold, shares);
      
      // Process result
      _lastResult = result;
      await _saveToHistory(result);
      
      _setLoading(false);
      return true;
      
    } on CryptographicException catch (e) {
      _setError('Cryptographic error: ${e.message}');
      _setLoading(false);
      return false;
      
    } catch (e) {
      _setError('Unexpected error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  
  // Cancellable operations
  CancelToken? _currentOperation;
  
  Future<void> performLongRunningOperation() async {
    // Cancel previous operation if running
    _currentOperation?.cancel();
    
    _currentOperation = CancelToken();
    
    try {
      await _doLongRunningWork(_currentOperation);
    } on OperationCancelledException {
      // Handle cancellation gracefully
      print('Operation was cancelled');
    } finally {
      _currentOperation = null;
    }
  }
  
  void cancelCurrentOperation() {
    _currentOperation?.cancel();
  }
}

// Stream handling for reactive updates
class AuthProvider extends ChangeNotifier {
  StreamSubscription? _lockoutSubscription;
  
  void startLockoutMonitoring() {
    _lockoutSubscription = Stream.periodic(Duration(seconds: 1))
        .listen((_) async {
      if (_isLocked) {
        final history = await _storageRepository.loadAttemptHistory();
        if (!history.isLocked()) {
          _isLocked = false;
          notifyListeners();
        }
      }
    });
  }
  
  @override
  void dispose() {
    _lockoutSubscription?.cancel();
    super.dispose();
  }
}
```

## Performance Optimizations

### Widget Performance

**Optimized Rendering**:

```dart
// Use const constructors where possible
class SecretFormHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  
  const SecretFormHeader({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8), // const for performance
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

// Optimize list performance with keys and builders
class SecretsListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SecretProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          itemCount: provider.secretHistory.length,
          itemBuilder: (context, index) {
            final secret = provider.secretHistory[index];
            return SecretListItem(
              key: ValueKey(secret.id), // Unique key for performance
              secretInfo: secret,
              onTap: () => _viewSecret(context, secret),
            );
          },
        );
      },
    );
  }
}

// Use RepaintBoundary for expensive widgets
class ShareCardWidget extends StatelessWidget {
  final ParticipantPackage package;
  
  const ShareCardWidget({Key? key, required this.package}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary( // Prevents unnecessary repaints
      child: Card(
        child: ExpansionTile(
          title: Text('Share ${package.participantIndex + 1}'),
          subtitle: Text('Participant ${package.participantId}'),
          children: [
            // Complex content that benefits from repaint boundary
            _buildShareContent(),
          ],
        ),
      ),
    );
  }
}
```

### Memory Optimization

**Efficient Memory Usage**:

```dart
// Lazy loading for heavy resources
class ShamirSecretSharing {
  // Static lookup tables initialized lazily
  static List<int>? _multiplicationTable;
  static List<int>? _inverseTable;
  
  static List<int> get multiplicationTable {
    return _multiplicationTable ??= _generateMultiplicationTable();
  }
  
  static List<int> get inverseTable {
    return _inverseTable ??= _generateInverseTable();
  }
  
  // Dispose pattern for cleanup
  void dispose() {
    // Clean up any resources
    _clearSensitiveData();
  }
}

// Object pooling for frequent allocations
class ByteArrayPool {
  static const int _poolSize = 10;
  static const int _defaultSize = 256;
  
  static final Queue<Uint8List> _pool = Queue<Uint8List>();
  
  static Uint8List acquire([int size = _defaultSize]) {
    if (_pool.isNotEmpty && _pool.first.length >= size) {
      final array = _pool.removeFirst();
      array.fillRange(0, array.length, 0); // Clear previous data
      return array;
    }
    return Uint8List(size);
  }
  
  static void release(Uint8List array) {
    if (_pool.length < _poolSize) {
      _pool.add(array);
    }
  }
}
```

## Deployment and Build Configuration

### Build Optimization

**Flutter Build Configuration**:

```yaml
# pubspec.yaml optimization
flutter:
  uses-material-design: true
  
  # Optimize asset loading
  assets:
    - assets/images/
    - assets/fonts/
  
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700

# Optimize dependencies
dependencies:
  flutter:
    sdk: flutter
  
  # Minimal required dependencies only
  provider: ^6.0.5
  crypto: ^3.0.3
  path_provider: ^2.0.15
  
  # Dev dependencies separate
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  test: ^1.24.0
```

**Build Scripts**:

```bash
#!/bin/bash
# build_release.sh

set -e

echo "🔧 Building SRSecrets Release..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Run tests
echo "🧪 Running tests..."
flutter test --coverage

# Verify coverage
echo "📊 Checking test coverage..."
genhtml coverage/lcov.info -o coverage/html
COVERAGE=$(lcov --summary coverage/lcov.info | grep "lines" | grep -oE '[0-9]+\.[0-9]+%' | head -1)
echo "Test coverage: $COVERAGE"

# Security checks
echo "🔒 Running security checks..."
dart run tools/security_audit.dart

# Build for platforms
echo "📱 Building for iOS..."
flutter build ios --release --no-codesign

echo "🤖 Building for Android..."
flutter build appbundle --release

echo "💻 Building for macOS..."
flutter build macos --release

echo "✅ Build completed successfully!"
```

**Environment Configuration**:

```dart
// config/environment.dart
enum Environment { development, staging, production }

class Config {
  static const Environment currentEnvironment = Environment.production;
  
  // Security settings based on environment
  static int get pbkdf2Iterations {
    switch (currentEnvironment) {
      case Environment.development:
        return 10000; // Faster for development
      case Environment.staging:
        return 50000; // Moderate for testing
      case Environment.production:
        return 100000; // Full security for production
    }
  }
  
  static bool get debugLogging {
    return currentEnvironment == Environment.development;
  }
  
  static Duration get sessionTimeout {
    switch (currentEnvironment) {
      case Environment.development:
        return Duration(hours: 8); // Long for development
      case Environment.staging:
        return Duration(hours: 1); // Moderate for testing  
      case Environment.production:
        return Duration(minutes: 15); // Secure for production
    }
  }
}
```

### Platform-Specific Configurations

**iOS Configuration (ios/Runner/Info.plist)**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App security settings -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>
    
    <!-- Prevent screenshots in app switcher -->
    <key>UIApplicationExitsOnSuspend</key>
    <true/>
    
    <!-- File protection -->
    <key>NSFileProtectionComplete</key>
    <true/>
    
    <!-- Bundle settings -->
    <key>CFBundleName</key>
    <string>SRSecrets</string>
    <key>CFBundleDisplayName</key>
    <string>SR Secrets</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
</dict>
</plist>
```

**Android Configuration (android/app/src/main/AndroidManifest.xml)**:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- No network permissions for air-gapped operation -->
    
    <application
        android:label="SRSecrets"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="false"
        android:exported="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:excludeFromRecents="false"
            android:theme="@style/LaunchTheme"
            android:screenOrientation="portrait">
            
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <!-- Prevent screenshot/recording -->
        <meta-data android:name="android.allow_screenshot" android:value="false" />
        
        <!-- Flutter embedding -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

These development guidelines ensure consistent, high-quality Flutter development that maintains security, performance, and maintainability standards throughout the SRSecrets project lifecycle.