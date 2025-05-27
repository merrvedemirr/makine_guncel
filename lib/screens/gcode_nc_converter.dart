import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:makine/utils/ui_helpers.dart';

/// A simple widget to directly convert GCode JSON to NC content
/// This implementation doesn't require any external packages
class GCodeNCConverter extends StatefulWidget {
  const GCodeNCConverter({super.key});

  @override
  State<GCodeNCConverter> createState() => _GCodeNCConverterState();
}

class _GCodeNCConverterState extends State<GCodeNCConverter> {
  bool _isProcessing = false;
  String? _ncContent;
  String? _errorMessage;
  TextEditingController jsonInputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GCode to NC Converter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: jsonInputController,
                    decoration: const InputDecoration(
                      labelText: 'Enter GCode JSON',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.code),
                  label: const Text('Load Sample'),
                  onPressed: processSampleGCode,
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : processGCodeJson,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Convert to NC'),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade100,
                width: double.infinity,
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ],
            if (_ncContent != null) ...[
              const SizedBox(height: 16),
              const Text(
                'NC Content:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        child: Text(_ncContent!),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _ncContent!));
                            UIHelpers.showSnackBar(
                              context,
                              message: 'NC content copied to clipboard',
                              isError: false,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Convert GCode JSON to NC content
  void processGCodeJson() {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _ncContent = null;
    });

    try {
      // Get input and validate
      final jsonInput = jsonInputController.text.trim();
      if (jsonInput.isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Please enter JSON data';
        });
        return;
      }

      // Parse JSON
      final Map<String, dynamic> jsonData = json.decode(jsonInput);

      // Check if 'cmd' exists in JSON and is a list
      if (!jsonData.containsKey('cmd') || jsonData['cmd'] is! List) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'JSON must contain a "cmd" array';
        });
        return;
      }

      // Convert commands to NC content
      final List<dynamic> commands = jsonData['cmd'];
      final String ncContent = commands.join('\n');

      // Successfully converted
      setState(() {
        _isProcessing = false;
        _ncContent = ncContent;
        UIHelpers.showSnackBar(context,
            message: 'Successfully converted to NC content', isError: false);
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e is FormatException
            ? 'Invalid JSON format. Please check your input.'
            : 'Error processing: $e';
      });
    }
  }

  // Process a sample GCode
  void processSampleGCode() {
    setState(() {
      jsonInputController.text = '''
{
  "user_id": 8,
  "makine_id": "1234-5678-9012-3456",
  "makine_ip": "192.168.1.1",
  "cmd": [
    "; LightBurn 1.7.04",
    "; GRBL device profile, absolute coords",
    "; Bounds: X18.9 Y15.17 to X110.98 Y193.17",
    "G00 G17 G40 G21 G54",
    "G90",
    "M4",
    "; Cut @ 12000 mm/min, 10% power",
    "M8",
    "G0 X44.635Y36.862",
    "; Layer C00",
    "G1 X44.631Y37.046S1000F16000",
    "G1 X44.592Y37.467",
    "G1 X44.513Y37.875",
    "G1 X44.397Y38.267",
    "G1 X44.246Y38.643",
    "G1 X44.06Y38.999",
    "G1 X43.843Y39.335",
    "G1 X43.597Y39.648"
  ]
}''';
    });
  }
}
