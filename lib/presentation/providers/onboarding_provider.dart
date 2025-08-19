import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding Provider for managing onboarding state and settings
/// Handles completion status, user preferences, and tutorial progress
class OnboardingProvider extends ChangeNotifier {
  bool _isOnboardingCompleted = false;
  bool _isFirstLaunch = true;
  bool _enableTutorialHints = true;
  bool _enableAnimations = true;
  bool _hasCompletedVisualTutorial = false;
  bool _hasCompletedUseCases = false;
  bool _hasCompletedSecurityGuide = false;
  OnboardingMode _preferredMode = OnboardingMode.guided;
  
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyTutorialHints = 'tutorial_hints_enabled';
  static const String _keyAnimations = 'animations_enabled';
  static const String _keyVisualTutorial = 'visual_tutorial_completed';
  static const String _keyUseCases = 'use_cases_completed';
  static const String _keySecurityGuide = 'security_guide_completed';
  static const String _keyPreferredMode = 'preferred_onboarding_mode';

  // Getters
  bool get isOnboardingCompleted => _isOnboardingCompleted;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get enableTutorialHints => _enableTutorialHints;
  bool get enableAnimations => _enableAnimations;
  bool get hasCompletedVisualTutorial => _hasCompletedVisualTutorial;
  bool get hasCompletedUseCases => _hasCompletedUseCases;
  bool get hasCompletedSecurityGuide => _hasCompletedSecurityGuide;
  OnboardingMode get preferredMode => _preferredMode;

  /// Check if all onboarding sections are completed
  bool get isFullyCompleted => 
      _hasCompletedVisualTutorial && 
      _hasCompletedUseCases && 
      _hasCompletedSecurityGuide;

  /// Get completion progress percentage (0.0 to 1.0)
  double get completionProgress {
    int completed = 0;
    if (_hasCompletedVisualTutorial) completed++;
    if (_hasCompletedUseCases) completed++;
    if (_hasCompletedSecurityGuide) completed++;
    return completed / 3.0;
  }

  /// Initialize provider and load saved preferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isOnboardingCompleted = prefs.getBool(_keyOnboardingCompleted) ?? false;
      _isFirstLaunch = prefs.getBool(_keyFirstLaunch) ?? true;
      _enableTutorialHints = prefs.getBool(_keyTutorialHints) ?? true;
      _enableAnimations = prefs.getBool(_keyAnimations) ?? true;
      _hasCompletedVisualTutorial = prefs.getBool(_keyVisualTutorial) ?? false;
      _hasCompletedUseCases = prefs.getBool(_keyUseCases) ?? false;
      _hasCompletedSecurityGuide = prefs.getBool(_keySecurityGuide) ?? false;
      
      final modeIndex = prefs.getInt(_keyPreferredMode) ?? 0;
      _preferredMode = OnboardingMode.values[modeIndex];
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing OnboardingProvider: $e');
      }
    }
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    _isOnboardingCompleted = true;
    _isFirstLaunch = false;
    await _savePreferences();
    notifyListeners();
  }

  /// Skip onboarding (still marks as completed but with different flag)
  Future<void> skipOnboarding() async {
    _isOnboardingCompleted = true;
    _isFirstLaunch = false;
    await _savePreferences();
    notifyListeners();
  }

  /// Mark visual tutorial as completed
  Future<void> completeVisualTutorial() async {
    _hasCompletedVisualTutorial = true;
    await _checkFullCompletion();
  }

  /// Mark use cases section as completed
  Future<void> completeUseCases() async {
    _hasCompletedUseCases = true;
    await _checkFullCompletion();
  }

  /// Mark security guide as completed
  Future<void> completeSecurityGuide() async {
    _hasCompletedSecurityGuide = true;
    await _checkFullCompletion();
  }

  /// Update tutorial hints preference
  Future<void> setTutorialHints(bool enabled) async {
    _enableTutorialHints = enabled;
    await _savePreferences();
    notifyListeners();
  }

  /// Update animations preference
  Future<void> setAnimations(bool enabled) async {
    _enableAnimations = enabled;
    await _savePreferences();
    notifyListeners();
  }

  /// Set preferred onboarding mode
  Future<void> setPreferredMode(OnboardingMode mode) async {
    _preferredMode = mode;
    await _savePreferences();
    notifyListeners();
  }

  /// Reset onboarding state (for development/testing)
  Future<void> resetOnboardingState() async {
    _isOnboardingCompleted = false;
    _isFirstLaunch = true;
    _hasCompletedVisualTutorial = false;
    _hasCompletedUseCases = false;
    _hasCompletedSecurityGuide = false;
    await _savePreferences();
    notifyListeners();
  }

  /// Check if full onboarding is completed and update state
  Future<void> _checkFullCompletion() async {
    if (isFullyCompleted && !_isOnboardingCompleted) {
      await completeOnboarding();
    } else {
      await _savePreferences();
      notifyListeners();
    }
  }

  /// Save all preferences to persistent storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_keyOnboardingCompleted, _isOnboardingCompleted);
      await prefs.setBool(_keyFirstLaunch, _isFirstLaunch);
      await prefs.setBool(_keyTutorialHints, _enableTutorialHints);
      await prefs.setBool(_keyAnimations, _enableAnimations);
      await prefs.setBool(_keyVisualTutorial, _hasCompletedVisualTutorial);
      await prefs.setBool(_keyUseCases, _hasCompletedUseCases);
      await prefs.setBool(_keySecurityGuide, _hasCompletedSecurityGuide);
      await prefs.setInt(_keyPreferredMode, _preferredMode.index);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving onboarding preferences: $e');
      }
    }
  }

  /// Get personalized welcome message based on completion state
  String getWelcomeMessage() {
    if (_isFirstLaunch) {
      return 'Welcome to SRSecrets! Let\'s get you started with the fundamentals.';
    } else if (!isFullyCompleted) {
      return 'Welcome back! Continue where you left off.';
    } else {
      return 'Welcome back! You can revisit any section anytime.';
    }
  }

  /// Get recommended next step
  String getNextRecommendedStep() {
    if (!_hasCompletedVisualTutorial) {
      return 'Start with Visual Tutorial to learn the basics';
    } else if (!_hasCompletedUseCases) {
      return 'Explore Real Use Cases to see practical applications';
    } else if (!_hasCompletedSecurityGuide) {
      return 'Review Security Guide for best practices';
    } else {
      return 'You\'re all set! Ready to use SRSecrets';
    }
  }
}

/// Onboarding mode preferences
enum OnboardingMode {
  guided,    // Full guided experience with hints
  quick,     // Streamlined experience
  expert,    // Minimal guidance for experienced users
}