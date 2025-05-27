import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:makine/controller/bluetooth_controller.dart';

class BluetoothTestScreen extends StatefulWidget {
  final BluetoothController controller;

  const BluetoothTestScreen({super.key, required this.controller});

  @override
  State<BluetoothTestScreen> createState() => _BluetoothTestScreenState();
}

class _BluetoothTestScreenState extends State<BluetoothTestScreen> {
  late final BluetoothController _controller;
  StreamSubscription? _dataStreamSubscription;
  String _deviceBuffer = '';
  final List<String> _testResults = [];

  final List<String> _testCommands = [
    'G0 X0 Y0',
    'G1 X10 Y10',
    'M5', // Spindle Stop
    'M8', // Coolant On
  ];

  int _currentCommandIndex = 0;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _listenForDeviceData();
  }

  void _listenForDeviceData() {
    final stream = _controller.getDataStream();
    if (stream == null) return;

    _dataStreamSubscription = stream.listen(
      (data) {
        _deviceBuffer += data;
        if (_deviceBuffer.toLowerCase().contains('ok')) {
          _testResults.add('✅ OK Alındı: ${_testCommands[_currentCommandIndex]}');
          _deviceBuffer = '';
          _currentCommandIndex++;
          _sendNextTestCommand();
          _scrollToEnd();
        } else if (_deviceBuffer.length > 100) {
          _testResults.add('❌ OK alınamadı (veri: $_deviceBuffer)');
          _scrollToEnd();
        }
      },
      onError: (error) {
        _testResults.add('❌ Veri akışı hatası: $error');
        _scrollToEnd();
      },
      onDone: () {
        _testResults.add('⚡ Bağlantı kapandı');
        _scrollToEnd();
      },
    );
  }

  void _sendNextTestCommand() {
    if (_currentCommandIndex < _testCommands.length) {
      final cmd = _testCommands[_currentCommandIndex];
      _controller.connection!.output.add(Uint8List.fromList(utf8.encode('$cmd\n')));
      _controller.connection!.output.allSent;
    } else {
      _testResults.add('✅ Tüm test komutları gönderildi.');
      _isTesting = false;
      setState(() {});
    }
  }

  void _startTest() {
    if (_isTesting) return;
    _testResults.clear();
    _currentCommandIndex = 0;
    _isTesting = true;
    _sendNextTestCommand();
    setState(() {});
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _dataStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Test Ekranı'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _startTest,
              child: const Text('🔍 Test Başlat'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _testResults.length,
                itemBuilder: (context, index) => Text(
                  _testResults[index],
                  style: TextStyle(
                    color: _testResults[index].contains('✅') ? Colors.green : Colors.redAccent,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
