import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:makine/model/gcode_processor_model.dart';

class GCodeProcessorService {
  // Convert GCode commands to NC file content
  String convertToNCContent(List<String> commands) {
    return commands.join('\n');
  }

  // Parse JSON response to GCodeData model
  GCodeData parseGCodeJson(String jsonString) {
    try {
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return GCodeData.fromJson(jsonData);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing JSON: $e');
      }
      throw Exception('Failed to parse GCode JSON: $e');
    }
  }

  // Generate NC file content from JSON string
  String processGCodeDataToString(String jsonString) {
    try {
      // Parse JSON to data model
      final gCodeData = parseGCodeJson(jsonString);

      // Get NC file content
      return convertToNCContent(gCodeData.commands);
    } catch (e) {
      if (kDebugMode) {
        print('Error processing GCode data: $e');
      }
      throw Exception('Failed to process GCode data: $e');
    }
  }
}
