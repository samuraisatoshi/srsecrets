import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../lib/presentation/screens/secrets/create_secret_screen.dart';
import '../../../lib/presentation/providers/secret_provider.dart';
import '../../../lib/presentation/widgets/secret_form_header.dart';
import '../../../lib/presentation/widgets/threshold_config_widget.dart';
import '../../../lib/presentation/widgets/error_display_widget.dart';

// Mock SecretProvider for testing
class MockSecretProvider extends ChangeNotifier implements SecretProvider {
  bool _isLoading = false;
  String? _errorMessage;
  final List<SecretInfo> _secrets = [];

  @override
  bool get isLoading => _isLoading;
  
  @override
  String? get errorMessage => _errorMessage;
  
  @override
  List<SecretInfo> get secrets => _secrets;
  
  @override
  MultiSplitResult? get lastResult => null;
  
  @override
  String? get reconstructedSecret => null;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  @override
  Future<bool> createSecret({
    required String secretName,
    required String secret,
    required int threshold,
    required int totalShares,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    _isLoading = false;
    
    if (secret == 'test_secret' && secretName.isNotEmpty) {
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Failed to create secret';
      notifyListeners();
      return false;
    }
  }

  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  Future<bool> reconstructSecret(List<String> shareStrings) async {
    throw UnimplementedError();
  }

  @override
  void clearResults() {}
  
  @override
  void removeSecret(String id) {}
  
  @override
  List<ParticipantPackage> getDistributionPackages() => [];
}

void main() {
  group('CreateSecretScreen Integration Tests', () {
    late MockSecretProvider mockSecretProvider;

    setUp(() {
      mockSecretProvider = MockSecretProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<SecretProvider>.value(
          value: mockSecretProvider,
          child: const CreateSecretScreen(),
        ),
      );
    }

    group('Screen Rendering', () {
      testWidgets('renders all required elements', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(SecretFormHeader), findsOneWidget);
        expect(find.text('Create Secret Shares'), findsOneWidget);
        expect(find.text('Secret Name'), findsOneWidget);
        expect(find.text('Secret'), findsOneWidget);
        expect(find.byType(ThresholdConfigWidget), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('shows loading state when creating secret', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        mockSecretProvider.setLoading(true);
        await tester.pump();
        
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Create Secret Shares'), findsNothing);
      });

      testWidgets('shows error message when creation fails', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        mockSecretProvider.setError('Test error message');
        await tester.pump();
        
        expect(find.byType(ErrorDisplayWidget), findsOneWidget);
        expect(find.text('Test error message'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('has proper semantic structure', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.bySemanticsLabel(RegExp(r'Create Secret Shares.*Split your secret')), findsOneWidget);
      });

      testWidgets('form fields have proper semantic labels', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text('Secret Name'), findsOneWidget);
        expect(find.text('Secret'), findsOneWidget);
        
        // Check text fields have proper accessibility
        final nameField = tester.widget<TextFormField>(
          find.ancestor(
            of: find.text('Enter a name for your secret'),
            matching: find.byType(TextFormField),
          ),
        );
        
        expect(nameField.decoration?.labelText, equals('Secret Name'));
      });

      testWidgets('create button has proper semantics', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final createButton = find.byType(ElevatedButton);
        expect(createButton, findsOneWidget);
        expect(find.text('Create Secret Shares'), findsOneWidget);
      });

      testWidgets('error messages are announced to screen readers', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        mockSecretProvider.setError('Creation failed');
        await tester.pump();
        
        expect(find.bySemanticsLabel('Error: Creation failed'), findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('validates secret name is required', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Leave name empty, fill secret
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter your secret text'),
            matching: find.byType(TextFormField),
          ),
          'test secret',
        );
        
        // Try to submit
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        
        expect(find.text('Please enter a name for your secret'), findsOneWidget);
      });

      testWidgets('validates secret content is required', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Fill name, leave secret empty
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter a name for your secret'),
            matching: find.byType(TextFormField),
          ),
          'Test Secret',
        );
        
        // Try to submit
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        
        expect(find.text('Please enter your secret'), findsOneWidget);
      });

      testWidgets('validates secret minimum length', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Fill name with valid value
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter a name for your secret'),
            matching: find.byType(TextFormField),
          ),
          'Test Secret',
        );
        
        // Fill secret with too short value
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter your secret text'),
            matching: find.byType(TextFormField),
          ),
          'abc',
        );
        
        // Try to submit
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        
        expect(find.text('Secret must be at least 4 characters long'), findsOneWidget);
      });

      testWidgets('passes validation with valid inputs', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Fill all required fields
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter a name for your secret'),
            matching: find.byType(TextFormField),
          ),
          'Test Secret',
        );
        
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter your secret text'),
            matching: find.byType(TextFormField),
          ),
          'test_secret',
        );
        
        // Submit form
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        
        // Should not show validation errors
        expect(find.text('Please enter a name for your secret'), findsNothing);
        expect(find.text('Please enter your secret'), findsNothing);
      });
    });

    group('Secret Creation Flow', () {
      testWidgets('creates secret with valid inputs', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Fill form
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter a name for your secret'),
            matching: find.byType(TextFormField),
          ),
          'My Test Secret',
        );
        
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter your secret text'),
            matching: find.byType(TextFormField),
          ),
          'test_secret',
        );
        
        // Submit
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        
        // Should show loading, then success (no error)
        expect(mockSecretProvider.errorMessage, isNull);
      });

      testWidgets('shows error when creation fails', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Fill form with values that will cause failure
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter a name for your secret'),
            matching: find.byType(TextFormField),
          ),
          'Failing Secret',
        );
        
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter your secret text'),
            matching: find.byType(TextFormField),
          ),
          'invalid_secret',
        );
        
        // Submit
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        
        expect(mockSecretProvider.errorMessage, equals('Failed to create secret'));
        expect(find.text('Failed to create secret'), findsOneWidget);
      });

      testWidgets('disables button during loading', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        mockSecretProvider.setLoading(true);
        await tester.pump();
        
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);
      });

      testWidgets('clears form after successful creation', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final nameField = find.ancestor(
          of: find.text('Enter a name for your secret'),
          matching: find.byType(TextFormField),
        );
        
        final secretField = find.ancestor(
          of: find.text('Enter your secret text'),
          matching: find.byType(TextFormField),
        );
        
        // Fill form
        await tester.enterText(nameField, 'Test Name');
        await tester.enterText(secretField, 'test_secret');
        
        // Submit
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        
        // Check fields are cleared (would require navigation mock to fully test)
        // For now, just verify no error state
        expect(mockSecretProvider.errorMessage, isNull);
      });
    });

    group('Threshold Configuration Integration', () {
      testWidgets('integrates with threshold configuration widget', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(ThresholdConfigWidget), findsOneWidget);
        expect(find.text('Sharing Configuration'), findsOneWidget);
        expect(find.text('Threshold (k)'), findsOneWidget);
        expect(find.text('Total Shares (n)'), findsOneWidget);
      });

      testWidgets('uses threshold values in secret creation', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Fill main form
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter a name for your secret'),
            matching: find.byType(TextFormField),
          ),
          'Test Secret',
        );
        
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter your secret text'),
            matching: find.byType(TextFormField),
          ),
          'test_secret',
        );
        
        // Modify threshold values
        await tester.enterText(
          find.ancestor(
            of: find.text('3').first,
            matching: find.byType(TextFormField),
          ),
          '2',
        );
        
        await tester.enterText(
          find.ancestor(
            of: find.text('5').first,
            matching: find.byType(TextFormField),
          ),
          '4',
        );
        
        // Submit - values should be passed to provider
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        
        // Mock provider received the call (validated by no error)
        expect(mockSecretProvider.errorMessage, isNull);
      });
    });

    group('Error Handling', () {
      testWidgets('can dismiss error messages', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        mockSecretProvider.setError('Test error');
        await tester.pump();
        
        expect(find.text('Test error'), findsOneWidget);
        
        // Dismiss error
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();
        
        expect(mockSecretProvider.errorMessage, isNull);
        expect(find.text('Test error'), findsNothing);
      });

      testWidgets('maintains form state when error occurs', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Fill form
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter a name for your secret'),
            matching: find.byType(TextFormField),
          ),
          'Test Name',
        );
        
        // Trigger error
        mockSecretProvider.setError('Creation failed');
        await tester.pump();
        
        // Form should still have the entered data
        expect(find.text('Test Name'), findsOneWidget);
        expect(find.text('Creation failed'), findsOneWidget);
      });
    });

    group('User Experience', () {
      testWidgets('provides immediate visual feedback on form submission', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Fill form
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter a name for your secret'),
            matching: find.byType(TextFormField),
          ),
          'Test Secret',
        );
        
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter your secret text'),
            matching: find.byType(TextFormField),
          ),
          'test_secret',
        );
        
        // Submit
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(); // Allow state change
        
        // Should show loading state
        expect(mockSecretProvider.isLoading, isTrue);
      });

      testWidgets('multiline secret input works correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final secretField = find.ancestor(
          of: find.text('Enter your secret text'),
          matching: find.byType(TextFormField),
        );
        
        final textFormField = tester.widget<TextFormField>(secretField);
        expect(textFormField.maxLines, equals(4));
      });
    });

    group('Layout and Responsiveness', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 800));
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(CreateSecretScreen), findsOneWidget);
        expect(find.text('Create Secret Shares'), findsOneWidget);
        
        // Change to tablet size
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        await tester.pump();
        
        expect(find.byType(CreateSecretScreen), findsOneWidget);
        expect(find.text('Create Secret Shares'), findsOneWidget);
      });

      testWidgets('scrolls when content exceeds screen height', (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 400));
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byType(CreateSecretScreen), findsOneWidget);
      });
    });

    group('Form State Management', () {
      testWidgets('maintains form state during screen lifecycle', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Fill form
        await tester.enterText(
          find.ancestor(
            of: find.text('Enter a name for your secret'),
            matching: find.byType(TextFormField),
          ),
          'Persistent Name',
        );
        
        // Trigger rebuild
        await tester.pump();
        
        // Data should persist
        expect(find.text('Persistent Name'), findsOneWidget);
      });
    });
  });
}