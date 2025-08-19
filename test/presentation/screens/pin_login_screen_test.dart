import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../lib/presentation/screens/auth/pin_login_screen.dart';
import '../../../lib/presentation/providers/auth_provider.dart';
import '../../../lib/presentation/widgets/pin_input_widget.dart';

// Mock AuthProvider for testing
class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  int _failedAttempts = 0;

  @override
  bool get isLoading => _isLoading;
  
  @override
  String? get errorMessage => _errorMessage;
  
  @override
  bool get isAuthenticated => _isAuthenticated;
  
  @override
  int get failedAttempts => _failedAttempts;
  
  @override
  bool get isLocked => _failedAttempts >= 3;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void setAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    notifyListeners();
  }

  void setFailedAttempts(int attempts) {
    _failedAttempts = attempts;
    notifyListeners();
  }

  @override
  Future<bool> login(String pin) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    _isLoading = false;
    
    if (pin == '1234') {
      _isAuthenticated = true;
      _errorMessage = null;
      _failedAttempts = 0;
    } else {
      _isAuthenticated = false;
      _errorMessage = 'Invalid PIN';
      _failedAttempts++;
    }
    
    notifyListeners();
    return _isAuthenticated;
  }

  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  Future<bool> setupPin(String pin, String confirmPin) async {
    throw UnimplementedError();
  }

  @override
  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  @override
  bool get hasPin => true;
}

void main() {
  group('PinLoginScreen Integration Tests', () {
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: const PinLoginScreen(),
        ),
      );
    }

    group('Screen Rendering', () {
      testWidgets('renders all required elements', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text('Welcome Back'), findsOneWidget);
        expect(find.text('Enter your PIN to access your secrets'), findsOneWidget);
        expect(find.byType(PinInputWidget), findsOneWidget);
        expect(find.byIcon(Icons.security), findsOneWidget);
      });

      testWidgets('shows loading indicator when authenticating', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        mockAuthProvider.setLoading(true);
        await tester.pump();
        
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows error message when authentication fails', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        mockAuthProvider.setError('Invalid PIN');
        await tester.pump();
        
        expect(find.text('Invalid PIN'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('has proper semantic structure', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.bySemanticsLabel(RegExp(r'Welcome Back.*Enter your PIN')), findsOneWidget);
      });

      testWidgets('error messages are announced to screen readers', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        mockAuthProvider.setError('Authentication failed');
        await tester.pump();
        
        expect(find.bySemanticsLabel('Error: Authentication failed'), findsOneWidget);
      });

      testWidgets('loading state is accessible', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        mockAuthProvider.setLoading(true);
        await tester.pump();
        
        // PinInputWidget should show loading state
        final pinInput = tester.widget<PinInputWidget>(find.byType(PinInputWidget));
        expect(pinInput.isLoading, isTrue);
      });
    });

    group('PIN Input Integration', () {
      testWidgets('completes login flow with correct PIN', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Enter correct PIN through keypad
        await tester.tap(find.text('1'));
        await tester.tap(find.text('2'));
        await tester.tap(find.text('3'));
        await tester.tap(find.text('4'));
        await tester.pumpAndSettle();
        
        expect(mockAuthProvider.isAuthenticated, isTrue);
        expect(mockAuthProvider.errorMessage, isNull);
      });

      testWidgets('shows error with incorrect PIN', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Enter incorrect PIN
        await tester.tap(find.text('1'));
        await tester.tap(find.text('1'));
        await tester.tap(find.text('1'));
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        
        expect(mockAuthProvider.isAuthenticated, isFalse);
        expect(mockAuthProvider.errorMessage, equals('Invalid PIN'));
        expect(mockAuthProvider.failedAttempts, equals(1));
      });

      testWidgets('handles multiple failed attempts', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Simulate multiple failed attempts
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.text('1'));
          await tester.tap(find.text('1'));
          await tester.tap(find.text('1'));
          await tester.tap(find.text('1'));
          await tester.pumpAndSettle();
          
          // Clear error for next attempt
          if (i < 2) {
            mockAuthProvider.clearError();
            await tester.pump();
          }
        }
        
        expect(mockAuthProvider.failedAttempts, equals(3));
        expect(mockAuthProvider.isLocked, isTrue);
      });
    });

    group('Error Handling', () {
      testWidgets('can dismiss error messages', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        mockAuthProvider.setError('Test error');
        await tester.pump();
        
        expect(find.text('Test error'), findsOneWidget);
        
        // Dismiss error by tapping dismiss button
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();
        
        expect(mockAuthProvider.errorMessage, isNull);
        expect(find.text('Test error'), findsNothing);
      });

      testWidgets('clears error when starting new PIN entry', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        mockAuthProvider.setError('Previous error');
        await tester.pump();
        
        // Start entering new PIN
        await tester.tap(find.text('1'));
        await tester.pump();
        
        // Error should be cleared when user starts new input
        expect(mockAuthProvider.errorMessage, isNull);
      });
    });

    group('User Experience', () {
      testWidgets('provides visual feedback during authentication', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Start PIN entry
        await tester.tap(find.text('1'));
        await tester.tap(find.text('2'));
        await tester.tap(find.text('3'));
        
        // Before completing PIN, should not be loading
        expect(mockAuthProvider.isLoading, isFalse);
        
        // Complete PIN - this triggers authentication
        await tester.tap(find.text('4'));
        await tester.pump(); // Allow state change
        
        // Should show loading state briefly
        expect(mockAuthProvider.isLoading, isTrue);
      });

      testWidgets('maintains focus on PIN input', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // PIN input should be focused on load
        final pinInputWidget = tester.state(find.byType(PinInputWidget));
        expect(pinInputWidget, isNotNull);
        
        // After entering incorrect PIN, focus should remain
        await tester.tap(find.text('1'));
        await tester.tap(find.text('1'));
        await tester.tap(find.text('1'));
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        
        // PIN should be cleared but input should still be focused
        expect(find.bySemanticsLabel('PIN entry: 0 of 8 digits entered'), findsOneWidget);
      });
    });

    group('Security Features', () {
      testWidgets('does not display entered PIN digits', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Enter some digits
        await tester.tap(find.text('1'));
        await tester.tap(find.text('2'));
        await tester.tap(find.text('3'));
        await tester.pump();
        
        // Should not show actual digits, only dots
        expect(find.text('123'), findsNothing);
        expect(find.bySemanticsLabel('PIN entry: 3 of 8 digits entered'), findsOneWidget);
      });

      testWidgets('clears PIN after failed attempt', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Enter incorrect PIN
        await tester.tap(find.text('9'));
        await tester.tap(find.text('9'));
        await tester.tap(find.text('9'));
        await tester.tap(find.text('9'));
        await tester.pumpAndSettle();
        
        // PIN should be cleared after failed attempt
        expect(find.bySemanticsLabel('PIN entry: 0 of 8 digits entered'), findsOneWidget);
      });

      testWidgets('tracks failed attempts correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Make failed attempt
        await tester.tap(find.text('0'));
        await tester.tap(find.text('0'));
        await tester.tap(find.text('0'));
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();
        
        expect(mockAuthProvider.failedAttempts, equals(1));
        
        // Clear error and try again
        mockAuthProvider.clearError();
        await tester.pump();
        
        await tester.tap(find.text('0'));
        await tester.tap(find.text('0'));
        await tester.tap(find.text('0'));
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();
        
        expect(mockAuthProvider.failedAttempts, equals(2));
      });
    });

    group('Layout and Responsiveness', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 800));
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(PinLoginScreen), findsOneWidget);
        
        // Change to tablet size
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        await tester.pump();
        
        expect(find.byType(PinLoginScreen), findsOneWidget);
        expect(find.text('Welcome Back'), findsOneWidget);
      });

      testWidgets('handles landscape orientation', (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 400));
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(PinLoginScreen), findsOneWidget);
        expect(find.text('Welcome Back'), findsOneWidget);
        expect(find.byType(PinInputWidget), findsOneWidget);
      });
    });
  });
}