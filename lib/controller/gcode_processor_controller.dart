import 'package:flutter/foundation.dart';
import 'package:makine/model/gcode_processor_model.dart';
import 'package:makine/service/gcode_processor_service.dart';

class GCodeProcessorController {
  final GCodeProcessorService _service = GCodeProcessorService();

  // Process JSON string to extract GCode data and convert to NC content
  Future<Map<String, dynamic>> processGCodeJsonToNC(String jsonString) async {
    try {
      // Call service to process GCode data to content string
      final ncContent = _service.processGCodeDataToString(jsonString);

      return {
        'success': true,
        'content': ncContent,
        'message': 'GCode successfully converted to NC content',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error in GCode processing controller: $e');
      }
      return {
        'success': false,
        'message': 'Failed to process GCode: $e',
      };
    }
  }

  // Process Map data directly (when data already parsed from JSON)
  Future<Map<String, dynamic>> processGCodeMapToNC(
      Map<String, dynamic> gCodeMap) async {
    try {
      // Create GCode data model from Map
      final gCodeData = GCodeData.fromJson(gCodeMap);

      // Get NC file content directly from model
      final ncContent = gCodeData.getNCFileContent();

      return {
        'success': true,
        'content': ncContent,
        'message': 'GCode successfully converted to NC content',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error in GCode processing controller: $e');
      }
      return {
        'success': false,
        'message': 'Failed to process GCode: $e',
      };
    }
  }
}
