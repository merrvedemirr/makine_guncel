import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/controller/bluetooth_controller.dart';
import 'package:makine/logger.dart';
import 'package:makine/model/bluetooth_device_model.dart';
import 'package:makine/viewmodel/provider.dart';

class BluetoothView extends ConsumerStatefulWidget {
  const BluetoothView({super.key});

  @override
  ConsumerState<BluetoothView> createState() => _BluetoothViewState();
}

class _BluetoothViewState extends ConsumerState<BluetoothView> {
  late final BluetoothController _controller;
  StreamSubscription? _dataStreamSubscription;
  final ScrollController _scrollController = ScrollController();
  final List<String> _logMessages = [];
  bool _isScanning = false;
  List<BluetoothDeviceModel> _devices = [];

  @override
  void initState() {
    super.initState();
    _controller = ref.read(bluetoothControllerProvider);
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    // Bluetooth izinlerini kontrol et
    bool permissionsGranted = await _controller.checkAndRequestPermissions();
    if (!permissionsGranted) {
      _addLogMessage("Bluetooth izinleri reddedildi!");
      return;
    }

    // Bluetooth açık mı kontrol et
    bool isEnabled = await _controller.enableBluetooth();
    if (!isEnabled) {
      _addLogMessage("Bluetooth açılamadı!");
      return;
    }

    // Eşleşmiş cihazları al
    _devices = await _controller.getPairedDevices();
    setState(() {});

    // Cihaz taramasını başlat
    _startScanning();
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });

    _controller.startDiscovery().listen(
      (device) {
        setState(() {
          if (!_devices.any((d) => d.address == device.address)) {
            _devices.add(device);
          }
        });
      },
      onDone: () {
        setState(() {
          _isScanning = false;
        });
      },
      onError: (error) {
        _addLogMessage("Tarama hatası: $error");
        setState(() {
          _isScanning = false;
        });
      },
    );
  }

  Future<void> _connectToDevice(BluetoothDeviceModel device) async {
    try {
      _addLogMessage("${device.name} cihazına bağlanılıyor...");
      bool connected = await _controller.connectToDevice(device);

      if (connected) {
        _addLogMessage("${device.name} cihazına bağlantı başarılı!");
        _listenForDeviceData();
        // Bağlantı başarılı olduğunda true döndür ve sayfayı kapat
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        _addLogMessage("${device.name} cihazına bağlantı başarısız!");
      }
    } catch (e) {
      _addLogMessage("Bağlantı hatası: $e");
    }
  }

  void _listenForDeviceData() {
    final stream = _controller.getDataStream();
    if (stream == null) {
      _addLogMessage("Cihazdan veri akışı alınamadı");
      return;
    }

    _dataStreamSubscription = stream.listen(
      (data) {
        _addLogMessage("Cihazdan gelen: $data");
      },
      onError: (error) {
        _addLogMessage("Veri akışı hatası: $error");
      },
      onDone: () {
        _addLogMessage("Veri akışı sonlandı");
      },
    );
  }

  void _addLogMessage(String message) {
    if (mounted) {
      setState(() {
        _logMessages.add("${DateTime.now().toString().substring(11, 19)}: $message");
      });

      // Scroll to the bottom of the log
      Future.delayed(const Duration(milliseconds: 100), () {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Bağlantısı'),
        actions: [
          if (_isScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScanning,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                final isConnected = _controller.selectedDevice?.address == device.address;

                return ListTile(
                  leading: Icon(
                    Icons.bluetooth,
                    color: isConnected ? Colors.blue : Colors.grey,
                  ),
                  title: Text(device.name ?? 'Bilinmeyen Cihaz'),
                  subtitle: Text(device.address),
                  trailing: isConnected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                  onTap: () => _connectToDevice(device),
                );
              },
            ),
          ),
          // Log mesajları
          Container(
            height: 200,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _logMessages.length,
              itemBuilder: (context, index) {
                return Text(
                  _logMessages[index],
                  style: const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dataStreamSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}
