import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../lib/presentation/providers/secret_provider.dart';
import '../lib/presentation/screens/secrets/create_secret_screen.dart';
import '../lib/presentation/screens/secrets/share_distribution_screen.dart';

void main() {
  testWidgets('Real navigation flow test', (WidgetTester tester) async {
    print('\n=== TESTING REAL NAVIGATION FLOW ===');
    
    // Create provider instance
    final secretProvider = SecretProvider();
    
    // Build the app with navigation
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: secretProvider,
          child: const CreateSecretScreen(),
        ),
      ),
    );
    
    print('1. CreateSecretScreen loaded');
    print('   Initial lastResult: ${secretProvider.lastResult}');
    
    // Fill in the form
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Secret');
    await tester.enterText(find.byType(TextFormField).at(1), 'My secret data');
    
    print('2. Form filled');
    
    // Find and tap the create button
    final createButton = find.text('Create Secret Shares');
    expect(createButton, findsOneWidget);
    
    print('3. About to tap Create Secret Shares button...');
    print('   Before tap - lastResult: ${secretProvider.lastResult}');
    
    await tester.tap(createButton);
    
    print('4. Button tapped');
    print('   After tap - lastResult: ${secretProvider.lastResult}');
    print('   isSecretReady: ${secretProvider.isSecretReady}');
    
    // Wait for navigation
    await tester.pumpAndSettle();
    
    print('5. After pumpAndSettle');
    print('   lastResult: ${secretProvider.lastResult}');
    print('   Current screen: ${find.byType(ShareDistributionScreen).evaluate().isNotEmpty ? "ShareDistributionScreen" : "Still on CreateSecretScreen"}');
    
    // Check if we navigated
    if (find.byType(ShareDistributionScreen).evaluate().isNotEmpty) {
      print('6. Successfully navigated to ShareDistributionScreen');
      print('   lastResult: ${secretProvider.lastResult}');
      
      // Check for error messages
      final errorFinder = find.text('No Shares Available');
      if (errorFinder.evaluate().isNotEmpty) {
        print('   ❌ ERROR: "No Shares Available" is displayed!');
        print('   lastResult at error: ${secretProvider.lastResult}');
      } else {
        print('   ✅ Shares are displayed correctly');
      }
    } else {
      print('6. Navigation did not occur');
      print('   Checking for error messages...');
      
      // Look for snackbar or error messages
      final snackbarFinder = find.byType(SnackBar);
      if (snackbarFinder.evaluate().isNotEmpty) {
        final snackBar = tester.widget<SnackBar>(snackbarFinder);
        print('   SnackBar message: ${(snackBar.content as Text).data}');
      }
    }
    
    print('\n=== END NAVIGATION TEST ===\n');
  });
}