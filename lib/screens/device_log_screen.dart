import 'dart:async';

import 'package:flutter/material.dart';
import 'package:makine/controller/bluetooth_controller.dart';
import 'package:makine/logger.dart';
import 'package:makine/screens/bluetooth/bluetooth_sender_screen.dart';
import 'package:makine/utils/ui_helpers.dart';

class DeviceLogScreen extends StatefulWidget {
  final String deviceName;
  final List<String> gcodeLines;
  final int delayMs;
  final BluetoothController controller;

  const DeviceLogScreen({
    super.key,
    required this.deviceName,
    required this.gcodeLines,
    required this.delayMs,
    required this.controller,
  });

  @override
  State<DeviceLogScreen> createState() => _DeviceLogScreenState();
}

class _DeviceLogScreenState extends State<DeviceLogScreen> {
  final List<String> _logMessages = [];
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  StreamSubscription? _logSubscription;

  @override
  void initState() {
    super.initState();
    _setupLogStream();

    // Başlangıç bağlantı mesajı ekle
    _addLogMessage("Bağlandı: ${widget.deviceName}");
  }

  void _setupLogStream() {
    // Cihazdan gelen log mesajlarını dinle
    _logSubscription = widget.controller.deviceLogStream.listen(
      (String message) {
        _addLogMessage(message);
      },
      onError: (error) {
        _addLogMessage("Hata: $error");
        logger.e("Log akışı hatası: $error");
      },
    );
  }

  void _addLogMessage(String message) {
    setState(() {
      _logMessages.add("${DateTime.now().toString().substring(11, 19)} > $message");

      // Log boyutunu yönetilebilir tut
      if (_logMessages.length > 500) {
        _logMessages.removeAt(0);
      }
    });

    // Otomatik kaydırma etkinse aşağı kaydır
    if (_autoScroll) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cihaz Logları: ${widget.deviceName}'),
        actions: [
          IconButton(
            icon: Icon(_autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center),
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });

              if (_autoScroll && _scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }

              UIHelpers.showSnackBar(
                context,
                message: _autoScroll ? 'Otomatik kaydırma açık' : 'Otomatik kaydırma kapalı',
                isError: false,
              );
            },
            tooltip: _autoScroll ? 'Otomatik kaydırmayı kapat' : 'Otomatik kaydırmayı aç',
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BluetoothSenderScreen(
                    deviceName: widget.deviceName,
                    gcodeLines: widget.gcodeLines,
                    controller: widget.controller,
                  ),
                ),
              );
            },
            tooltip: 'GCode Gönder',
          ),
        ],
      ),
      body: Column(
        children: [
          // Durum kartı
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cihaz: ${widget.deviceName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Bağlantı durumu: ${widget.controller.isConnected ? 'Bağlı' : 'Bağlantı kesildi'}'),
                const SizedBox(height: 8),
                Text('GCode satır sayısı: ${widget.gcodeLines.length}'),
              ],
            ),
          ),

          // Log container
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade600),
              ),
              child: _logMessages.isEmpty
                  ? const Center(
                      child: Text(
                        'Henüz log mesajı yok...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _logMessages.length,
                      itemBuilder: (context, index) {
                        final message = _logMessages[index];
                        Color textColor = Colors.green.shade300;

                        if (message.contains("Hata") || message.contains("hata")) {
                          textColor = Colors.red.shade300;
                        } else if (message.contains("Cihazdan gelen")) {
                          textColor = Colors.yellow.shade300;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            message,
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Kontrol butonları
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BluetoothSenderScreen(
                            deviceName: widget.deviceName,
                            gcodeLines: widget.gcodeLines,
                            controller: widget.controller,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('GCode Gönder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _logMessages.clear();
                      _addLogMessage("Log temizlendi");
                    });
                  },
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: 'Logları Temizle',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
