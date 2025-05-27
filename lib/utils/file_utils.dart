import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileUtils {
  /// Save content to a file in Downloads folder (Android) or Documents (iOS)
  static Future<String?> saveToDownloads(
      String content, String fileName) async {
    try {
      // Request storage permission
      if (!await _requestPermission()) {
        return null;
      }

      Directory? directory;

      if (Platform.isAndroid) {
        // For Android
        directory = Directory('/storage/emulated/0/Download');
        // Check if directory exists
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // For iOS
        directory = await getApplicationDocumentsDirectory();
      } else {
        // For other platforms
        directory = await getApplicationDocumentsDirectory();
      }

      final filePath = '${directory?.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(content);

      if (kDebugMode) {
        print('File saved at: $filePath');
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving file to downloads: $e');
      }
      return null;
    }
  }

  /// Save content to a file with specified name in app's documents directory
  static Future<String?> saveToFile(String content, String fileName) async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      // Create and write to the file
      final file = File(filePath);
      await file.writeAsString(content);

      if (kDebugMode) {
        print('File saved at: $filePath');
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving file: $e');
      }
      return null;
    }
  }

  /// Request storage permission
  static Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true; // iOS doesn't need storage permission for app documents
  }
}
