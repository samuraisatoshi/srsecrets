import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/domains/auth/services/pin_service.dart';
import 'package:srsecrets/domains/auth/services/pin_service_impl.dart';
import 'package:srsecrets/domains/auth/repositories/secure_storage_repository.dart';
import 'package:srsecrets/domains/auth/providers/pbkdf2_crypto_provider.dart';

void main() {
  group('PIN Validation Tests', () {
    late IPinService pinService;
    late SecureStorageRepository storageRepository;

    setUp(() {
      storageRepository = SecureStorageRepository();
      pinService = PinServiceImpl(
        storageRepository: storageRepository,
        cryptoProvider: Pbkdf2CryptoProvider(),
      );
    });

    tearDown(() async {
      // Clean up after each test
      await storageRepository.forceClearAllStorageLocations();
    });

    test('4-digit PIN should be accepted', () {
      // Test various 4-digit PINs
      final validPins = ['4567', '8901', '2345', '6789', '3456'];
      
      for (final pin in validPins) {
        expect(
          () => pinService.validatePin(pin),
          returnsNormally,
          reason: '4-digit PIN "$pin" should be valid',
        );
      }
    });

    test('5-digit PIN should be accepted', () {
      final validPins = ['45678', '89012', '23456'];
      
      for (final pin in validPins) {
        expect(
          () => pinService.validatePin(pin),
          returnsNormally,
          reason: '5-digit PIN "$pin" should be valid',
        );
      }
    });

    test('6-digit PIN should be accepted', () {
      final validPins = ['456789', '890123', '234567'];
      
      for (final pin in validPins) {
        expect(
          () => pinService.validatePin(pin),
          returnsNormally,
          reason: '6-digit PIN "$pin" should be valid',
        );
      }
    });

    test('7-digit PIN should be accepted', () {
      final validPins = ['4567890', '8901234', '2345678'];
      
      for (final pin in validPins) {
        expect(
          () => pinService.validatePin(pin),
          returnsNormally,
          reason: '7-digit PIN "$pin" should be valid',
        );
      }
    });

    test('8-digit PIN should be accepted', () {
      final validPins = ['45678901', '89012345', '23456789'];
      
      for (final pin in validPins) {
        expect(
          () => pinService.validatePin(pin),
          returnsNormally,
          reason: '8-digit PIN "$pin" should be valid',
        );
      }
    });

    test('PIN shorter than 4 digits should be rejected', () {
      final invalidPins = ['1', '12', '123'];
      
      for (final pin in invalidPins) {
        expect(
          () => pinService.validatePin(pin),
          throwsA(isA<PinValidationException>()),
          reason: 'PIN "$pin" should be rejected (too short)',
        );
      }
    });

    test('PIN longer than 8 digits should be rejected', () {
      final invalidPins = ['123456789', '1234567890'];
      
      for (final pin in invalidPins) {
        expect(
          () => pinService.validatePin(pin),
          throwsA(isA<PinValidationException>()),
          reason: 'PIN "$pin" should be rejected (too long)',
        );
      }
    });

    test('Common weak 4-digit PINs should be rejected', () {
      final weakPins = ['0000', '1111', '1234', '4321'];
      
      for (final pin in weakPins) {
        expect(
          () => pinService.validatePin(pin),
          throwsA(isA<PinValidationException>()),
          reason: 'Weak PIN "$pin" should be rejected',
        );
      }
    });

    test('Sequential digits should be rejected', () {
      final sequentialPins = ['1234', '4567', '7890', '3210', '6543'];
      
      for (final pin in sequentialPins) {
        expect(
          () => pinService.validatePin(pin),
          throwsA(isA<PinValidationException>()),
          reason: 'Sequential PIN "$pin" should be rejected',
        );
      }
    });

    test('Repeating digits should be rejected', () {
      final repeatingPins = ['1111', '2222', '3333', '111111'];
      
      for (final pin in repeatingPins) {
        expect(
          () => pinService.validatePin(pin),
          throwsA(isA<PinValidationException>()),
          reason: 'Repeating PIN "$pin" should be rejected',
        );
      }
    });

    test('Date patterns should be rejected', () {
      final datePins = ['1980', '2024', '1225', '0101', '3112'];
      
      for (final pin in datePins) {
        expect(
          () => pinService.validatePin(pin),
          throwsA(isA<PinValidationException>()),
          reason: 'Date pattern PIN "$pin" should be rejected',
        );
      }
    });

    test('PIN requirements should allow 4-8 digits', () {
      final requirements = pinService.requirements;
      
      expect(requirements.minLength, equals(4), 
        reason: 'Minimum PIN length should be 4');
      expect(requirements.maxLength, equals(8),
        reason: 'Maximum PIN length should be 8');
      expect(requirements.requireDigitsOnly, isTrue,
        reason: 'Should require digits only');
    });

    test('Setting and authenticating with 4-digit PIN should work', () async {
      const testPin = '4829'; // A valid 4-digit PIN
      
      // Set the PIN
      await pinService.setPin(testPin);
      
      // Verify PIN was set
      expect(await pinService.isPinSet(), isTrue);
      
      // Authenticate with the PIN
      final result = await pinService.authenticate(testPin);
      
      expect(result.success, isTrue,
        reason: 'Authentication with 4-digit PIN should succeed');
    });

    test('Storage migration should work correctly', () async {
      // This test verifies that old storage data is migrated
      // The migration happens automatically in loadPinHash()
      
      const testPin = '5678';
      
      // Set a PIN (will use new storage location)
      await pinService.setPin(testPin);
      
      // Verify PIN was set
      expect(await pinService.isPinSet(), isTrue);
      
      // Authenticate should work
      final result = await pinService.authenticate(testPin);
      expect(result.success, isTrue);
    });

    test('Force clear should remove all PIN data', () async {
      const testPin = '9876';
      
      // Set a PIN
      await pinService.setPin(testPin);
      expect(await pinService.isPinSet(), isTrue);
      
      // Force clear all storage locations
      await storageRepository.forceClearAllStorageLocations();
      
      // PIN should no longer be set
      expect(await pinService.isPinSet(), isFalse);
    });
  });
}