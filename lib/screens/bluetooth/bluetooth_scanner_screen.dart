import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/controller/bluetooth_controller.dart';
import 'package:makine/logger.dart';
import 'package:makine/model/bluetooth_device_model.dart';
import 'package:makine/screens/bluetooth/bluetooth_sender_screen.dart';
import 'package:makine/screens/bluetooth/bluetooth_test_sender.dart';
import 'package:makine/utils/ui_helpers.dart';
import 'package:makine/viewmodel/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class BluetoothScannerScreen extends ConsumerStatefulWidget {
  const BluetoothScannerScreen({super.key});

  @override
  ConsumerState<BluetoothScannerScreen> createState() => _BluetoothScannerScreenState();
}

class _BluetoothScannerScreenState extends ConsumerState<BluetoothScannerScreen> {
  late final BluetoothController _controller;
  List<BluetoothDeviceModel> _pairedDevices = [];
  List<BluetoothDeviceModel> _discoveredDevices = [];
  bool _isLoading = true;
  bool _isScanning = false;
  StreamSubscription? _discoverySubscription;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(bluetoothControllerProvider);
    _initBluetooth();
    _getPairedDevices();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    //_autoConnectBluetooth();
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // State provider'dan bağlı cihazı izle
    final connectedDevice = ref.watch(connectedBluetoothDeviceProvider);
    final isConnected = connectedDevice != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Bluetooth Cihazları'),
        actions: [
          if (_isScanning)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopDiscovery,
              tooltip: 'Taramayı Durdur',
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startDiscovery,
              tooltip: 'Cihazları Tara',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Discovered devices section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bulunan Cihazlar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isScanning ? _stopDiscovery : _startDiscovery,
                          icon: Icon(
                            _isScanning ? Icons.stop : Icons.search,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isScanning ? 'Durdur' : 'Tara',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isScanning ? Colors.red : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _discoveredDevices.isEmpty
                        ? SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Cihaz bulunamadı',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (!_isScanning)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Tarama başlatmak için "Tara" düğmesine basın',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _discoveredDevices.length,
                            itemBuilder: (context, index) {
                              final device = _discoveredDevices[index];
                              // Skip devices that are already in paired list
                              if (_pairedDevices.any((d) => d.address == device.address)) {
                                return const SizedBox.shrink();
                              }
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.bluetooth_searching,
                                    color: Colors.blue.shade400,
                                  ),
                                  title: Text(device.name),
                                  subtitle: Text(device.address),
                                  trailing: ElevatedButton(
                                    onPressed: () => _connectToDevice(device),
                                    child: const Text('Bağlan'),
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 10),
                    // Banner for scanning status
                    if (_isScanning)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Cihazlar taranıyor...',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Paired devices section
                    const Text(
                      'Eşleştirilmiş Cihazlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _pairedDevices.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Eşleştirilmiş cihaz bulunamadı',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _pairedDevices.length,
                            itemBuilder: (context, index) {
                              final device = _pairedDevices[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.bluetooth,
                                    color: Colors.blue.shade700,
                                  ),
                                  title: Text(device.name),
                                  subtitle: Text(device.address),
                                  trailing: ElevatedButton(
                                    onPressed: () => _connectToDevice(device),
                                    child: const Text('Bağlan'),
                                  ),
                                ),
                              );
                            },
                          ),

                    // Bağlı cihaz gösterimi
                    if (isConnected)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          color: Colors.green.shade100,
                          child: ListTile(
                            leading: const Icon(Icons.bluetooth_connected, color: Colors.green),
                            title: Text('Bağlı: ${connectedDevice.name}'),
                            subtitle: Text(connectedDevice.address),
                            trailing: IconButton(
                              icon: const Icon(Icons.link_off, color: Colors.red),
                              onPressed: _disconnectDevice,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _connectToDevice(BluetoothDeviceModel device) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Controller ile bağlantı yap
      bool connected = await _controller.connectToDevice(device);

      if (connected) {
        // Bağlantı başarılıysa state provider'ı güncelle
        ref.read(connectedBluetoothDeviceProvider.notifier).state = device;

        if (mounted) {
          UIHelpers.showSnackBar(
            context,
            message: '${device.name} cihazına bağlandı',
            isError: false,
          );
        }
      } else {
        // Bağlantı başarısızsa state provider'ı temizle
        ref.read(connectedBluetoothDeviceProvider.notifier).state = null;

        if (mounted) {
          UIHelpers.showSnackBar(
            context,
            message: '${device.name} cihazına bağlanılamadı, ${device.type} cihazına bağlanıyoruz',
            isError: true,
          );
        }
      }
    } catch (e) {
      // Hata durumunda state provider'ı temizle
      ref.read(connectedBluetoothDeviceProvider.notifier).state = null;

      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          message: 'Bağlantı hatası: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Bağlantıyı kes
  Future<void> _disconnectDevice() async {
    try {
      await _controller.disconnect();
      // Provider'ı güncelle
      ref.read(connectedBluetoothDeviceProvider.notifier).state = null;
    } catch (e) {
      print('Bağlantı kesme hatası: $e');
    }
  }

  Future<void> _initBluetooth() async {
    setState(() {
      _isLoading = true;
    });

    // Request permissions
    bool permissionsGranted = await _controller.checkAndRequestPermissions();
    if (!permissionsGranted) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          message: 'Bluetooth izinleri reddedildi. Cihazı tarayamıyoruz.',
          isError: true,
        );
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // Enable Bluetooth
    bool bluetoothEnabled = await _controller.enableBluetooth();
    if (!bluetoothEnabled) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          message: 'Bluetooth etkinleştirilmedi. Cihazı tarayamıyoruz.',
          isError: true,
        );
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // // Get paired devices
    _pairedDevices = await _controller.getPairedDevices();

    // Daha önce bağlanılan cihazı bul ve otomatik bağlanmayı dene
    final prefs = await SharedPreferences.getInstance();
    final lastAddress = prefs.getString('lastConnectedDeviceAddress');
    if (lastAddress != null && _pairedDevices.isNotEmpty) {
      BluetoothDeviceModel? lastDevice;
      try {
        lastDevice = _pairedDevices.firstWhere((d) => d.address == lastAddress);
      } catch (e) {
        lastDevice = null;
      }
      if (lastDevice != null) {
        // Otomatik bağlanmayı dene
        await _connectToDevice(lastDevice);
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getPairedDevices() async {
    try {
      _pairedDevices = await _controller.getPairedDevices();
      setState(() {});
    } catch (e) {
      print('Eşleştirilmiş cihazları alma hatası: $e');
    }
  }

  void _startDiscovery() {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _discoveredDevices = [];
    });

    _discoverySubscription = _controller.startDiscovery().listen(
      (device) {
        setState(() {
          if (!_discoveredDevices.any((d) => d.address == device.address)) {
            _discoveredDevices.add(device);
          }
        });
      },
      onDone: () {
        setState(() {
          _isScanning = false;
        });
      },
      onError: (error) {
        UIHelpers.showSnackBar(
          context,
          message: 'Cihaz tarama hatası: $error',
          isError: true,
        );
        setState(() {
          _isScanning = false;
        });
      },
    );
  }

  void _stopDiscovery() {
    _discoverySubscription?.cancel();
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _autoConnectBluetooth() async {
    final controller = ref.read(bluetoothControllerProvider);
    if (controller.connection != null) return; // Zaten bağlıysa tekrar bağlanma

    final prefs = await SharedPreferences.getInstance();
    final lastAddress = prefs.getString('lastConnectedDeviceAddress');
    if (lastAddress != null) {
      // Cihaz listesi alınmalı ve eşleşen cihaza bağlanılmalı
      final pairedDevices = await controller.getPairedDevices();
      BluetoothDeviceModel? lastDevice;
      try {
        lastDevice = pairedDevices.firstWhere((d) => d.address == lastAddress);
      } catch (e) {
        lastDevice = null;
      }
      if (lastDevice != null) {
        await controller.connectToDevice(lastDevice);
      }
    }
  }
}
