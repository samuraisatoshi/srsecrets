/// PIN Storage Diagnostic Utility
/// 
/// Provides diagnostic tools to check and fix PIN storage issues
library;

import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PinStorageDiagnostic {
  /// Check all possible storage locations for PIN data
  static Future<Map<String, dynamic>> checkAllStorageLocations() async {
    Map<String, dynamic> report = {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
      'locations': [],
    };
    
    try {
      // Check Application Documents Directory (old location)
      Directory appDocDir = await getApplicationDocumentsDirectory();
      Directory oldSecureDir = Directory('${appDocDir.path}/secure_auth');
      
      Map<String, dynamic> oldLocation = {
        'name': 'Application Documents (OLD)',
        'path': oldSecureDir.path,
        'exists': await oldSecureDir.exists(),
        'files': [],
      };
      
      if (await oldSecureDir.exists()) {
        await for (var entity in oldSecureDir.list()) {
          if (entity is File) {
            oldLocation['files'].add({
              'name': entity.path.split('/').last,
              'size': await entity.length(),
              'modified': (await entity.lastModified()).toIso8601String(),
            });
          }
        }
      }
      
      report['locations'].add(oldLocation);
      
      // Check Application Support Directory (new location for iOS/macOS)
      if (Platform.isIOS || Platform.isMacOS) {
        Directory appSupportDir = await getApplicationSupportDirectory();
        Directory newSecureDir = Directory('${appSupportDir.path}/secure_auth');
        
        Map<String, dynamic> newLocation = {
          'name': 'Application Support (NEW)',
          'path': newSecureDir.path,
          'exists': await newSecureDir.exists(),
          'files': [],
        };
        
        if (await newSecureDir.exists()) {
          await for (var entity in newSecureDir.list()) {
            if (entity is File) {
              newLocation['files'].add({
                'name': entity.path.split('/').last,
                'size': await entity.length(),
                'modified': (await entity.lastModified()).toIso8601String(),
              });
            }
          }
        }
        
        report['locations'].add(newLocation);
      }
      
      // Check Temporary Directory (should not have PIN data)
      Directory tempDir = await getTemporaryDirectory();
      Directory tempSecureDir = Directory('${tempDir.path}/secure_auth');
      
      Map<String, dynamic> tempLocation = {
        'name': 'Temporary Directory',
        'path': tempSecureDir.path,
        'exists': await tempSecureDir.exists(),
        'files': [],
        'warning': await tempSecureDir.exists() ? 'PIN data should NOT be in temp directory!' : null,
      };
      
      if (await tempSecureDir.exists()) {
        await for (var entity in tempSecureDir.list()) {
          if (entity is File) {
            tempLocation['files'].add({
              'name': entity.path.split('/').last,
              'size': await entity.length(),
              'modified': (await entity.lastModified()).toIso8601String(),
            });
          }
        }
      }
      
      report['locations'].add(tempLocation);
      
    } catch (e) {
      report['error'] = 'Diagnostic failed: $e';
    }
    
    return report;
  }
  
  /// Clean up all PIN storage locations (USE WITH CAUTION)
  static Future<Map<String, dynamic>> cleanupAllStorageLocations() async {
    Map<String, dynamic> result = {
      'timestamp': DateTime.now().toIso8601String(),
      'cleaned': [],
      'errors': [],
    };
    
    try {
      // Clean Application Documents Directory
      Directory appDocDir = await getApplicationDocumentsDirectory();
      Directory oldSecureDir = Directory('${appDocDir.path}/secure_auth');
      
      if (await oldSecureDir.exists()) {
        try {
          await oldSecureDir.delete(recursive: true);
          result['cleaned'].add('Application Documents: ${oldSecureDir.path}');
        } catch (e) {
          result['errors'].add('Failed to clean Documents: $e');
        }
      }
      
      // Clean Application Support Directory (iOS/macOS)
      if (Platform.isIOS || Platform.isMacOS) {
        Directory appSupportDir = await getApplicationSupportDirectory();
        Directory newSecureDir = Directory('${appSupportDir.path}/secure_auth');
        
        if (await newSecureDir.exists()) {
          try {
            await newSecureDir.delete(recursive: true);
            result['cleaned'].add('Application Support: ${newSecureDir.path}');
          } catch (e) {
            result['errors'].add('Failed to clean Support: $e');
          }
        }
      }
      
      // Clean Temporary Directory (if somehow PIN data ended up there)
      Directory tempDir = await getTemporaryDirectory();
      Directory tempSecureDir = Directory('${tempDir.path}/secure_auth');
      
      if (await tempSecureDir.exists()) {
        try {
          await tempSecureDir.delete(recursive: true);
          result['cleaned'].add('Temporary Directory: ${tempSecureDir.path}');
          result['warnings'] = ['PIN data was found in temp directory - this should not happen!'];
        } catch (e) {
          result['errors'].add('Failed to clean Temp: $e');
        }
      }
      
      result['success'] = result['errors'].isEmpty;
      
    } catch (e) {
      result['errors'].add('Cleanup failed: $e');
      result['success'] = false;
    }
    
    return result;
  }
  
  /// Get storage recommendations based on platform
  static Map<String, String> getStorageRecommendations() {
    final platform = Platform.operatingSystem;
    
    return {
      'platform': platform,
      'recommendation': _getRecommendationForPlatform(platform),
      'reason': _getReasonForPlatform(platform),
    };
  }
  
  static String _getRecommendationForPlatform(String platform) {
    switch (platform) {
      case 'ios':
      case 'macos':
        return 'Use Application Support Directory (Library/Application Support)';
      case 'android':
        return 'Use Application Documents Directory (app-specific internal storage)';
      case 'linux':
      case 'windows':
        return 'Use Application Support or Documents Directory with proper permissions';
      default:
        return 'Use Application Documents Directory';
    }
  }
  
  static String _getReasonForPlatform(String platform) {
    switch (platform) {
      case 'ios':
      case 'macos':
        return 'Application Support is cleared on uninstall and not backed up to iCloud';
      case 'android':
        return 'Internal storage is automatically cleared on app uninstall';
      case 'linux':
      case 'windows':
        return 'Ensures data is kept in user-specific location with proper permissions';
      default:
        return 'Standard location for application data';
    }
  }
  
  /// Print a formatted diagnostic report
  static void printDiagnosticReport(Map<String, dynamic> report) {
    print('\n=== PIN Storage Diagnostic Report ===');
    print('Timestamp: ${report['timestamp']}');
    print('Platform: ${report['platform']}');
    
    if (report.containsKey('error')) {
      print('\nERROR: ${report['error']}');
      return;
    }
    
    print('\nStorage Locations:');
    for (var location in report['locations']) {
      print('\n  ${location['name']}:');
      print('    Path: ${location['path']}');
      print('    Exists: ${location['exists']}');
      
      if (location['warning'] != null) {
        print('    ⚠️  WARNING: ${location['warning']}');
      }
      
      if (location['files'].isNotEmpty) {
        print('    Files:');
        for (var file in location['files']) {
          print('      - ${file['name']} (${file['size']} bytes, modified: ${file['modified']})');
        }
      }
    }
    
    print('\n=== End of Report ===\n');
  }
}