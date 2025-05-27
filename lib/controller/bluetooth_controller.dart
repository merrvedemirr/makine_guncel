import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:makine/logger.dart';
import 'package:makine/model/bluetooth_device_model.dart';
import 'package:makine/service/bluetooth_service.dart';
import 'package:makine/viewmodel/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothController {
  final BluetoothService _bluetoothService = BluetoothService();

  // Keep track of discovered devices
  final List<BluetoothDeviceModel> _discoveredDevices = [];

  // Selected device
  BluetoothDeviceModel? _selectedDevice;

  final StreamController<String> _logStreamController = StreamController<String>.broadcast();

  // Getters
  Stream<String> get deviceLogStream => _logStreamController.stream;

  List<BluetoothDeviceModel> get discoveredDevices => _discoveredDevices;
  bool get isConnected => _bluetoothService.isConnected;
  BluetoothDeviceModel? get selectedDevice => _selectedDevice;
  BluetoothConnection? get connection => _bluetoothService.connection;

  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  final StreamController<String> _rawDataStreamController = StreamController<String>.broadcast();
  Stream<String> get broadcastDataStream => _rawDataStreamController.stream;

// Mevcut bağlantı durumunu değiştirirken bu fonksiyonla bildir:
  void updateConnectionStatus(bool isConnected) {
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(isConnected);
    }
  }

// Method to add log messages
  void addLogMessage(String message) {
    if (!_logStreamController.isClosed) {
      _logStreamController.add(message);
    }
  }

  // Check and request permissions
  Future<bool> checkAndRequestPermissions() async {
    return await _bluetoothService.requestPermissions();
  }

  // Connect to a device
  Future<bool> connectToDevice(BluetoothDeviceModel device) async {
    // First verify we're not already connected
    if (isConnected) {
      logger.i('Already connected to a device, disconnecting first');
      await disconnect();
    }

    // Log the device we're trying to connect to
    logger.i('Attempting to connect to device: ${device.name} (${device.address})');
    addLogMessage("Cihaza bağlanılıyor: ${device.name}");

    bool connected = await _bluetoothService.connectTooDevice(device);

    if (connected) {
      // Son bağlanılan cihaz olarak kaydet
      updateConnectionStatus(true);
      // input stream'i dinle ve broadcast stream'e veri aktar
      _bluetoothService.connection?.input!
          .cast<List<int>>() // Uint8List => List<int>
          .transform(utf8.decoder) // List<int> => String
          .listen((data) {
        _rawDataStreamController.add(data);
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lastConnectedDeviceAddress', device.address);
        await prefs.setString('lastConnectedDeviceName', device.name);
      } catch (e) {
        logger.e('Error saving last connected device: $e');
      }
      logger.i('Successfully connected to device: ${device.name}');
      addLogMessage("Bağlantı başarılı: ${device.name}");
    } else {
      updateConnectionStatus(false);
      logger.e('Failed to connect to device: ${device.name}');
    }
    return connected;
  }

  // Disconnect from device
  Future<void> disconnect() async {
    logger.i('Disconnecting from device');
    await _bluetoothService.disconnect();
    updateConnectionStatus(false);
    logger.i('Device disconnected');
  }

  // Clean up resources
  void dispose() {
    logger.i('Disposing BluetoothController, disconnecting from device');
    _logStreamController.close();
    _rawDataStreamController.close();
    _bluetoothService.disconnect();
    _selectedDevice = null;
  }

  // Enable Bluetooth if not enabled
  Future<bool> enableBluetooth() async {
    bool isEnabled = await _bluetoothService.isBluetoothEnabled();
    if (!isEnabled) {
      isEnabled = await _bluetoothService.requestEnable();
    }
    return isEnabled;
  }

  // Get data stream from device
  Stream<String> getDataStream() {
    return broadcastDataStream;
  }

  // Get paired devices
  Future<List<BluetoothDeviceModel>> getPairedDevices() async {
    return await _bluetoothService.getBondedDevices();
  }

  // Send GCode lines to the device
  Future<bool> sendGCodeLines(List<String> lines, int delayMs) async {
    if (!_bluetoothService.isConnected || _selectedDevice == null) {
      logger.e(
          'Not connected to any device or selected device is null. Selected device: $_selectedDevice, isConnected: ${_bluetoothService.isConnected}');
      return false;
    }

    logger.i('Sending GCode lines to device: ${_selectedDevice!.name}');
    return await _bluetoothService.sendGCodeLines(lines, delayMs);
  }

  // Send a single line to the device
  Future<bool> sendSingleLine(String line) async {
    if (!_bluetoothService.isConnected || _selectedDevice == null) {
      logger.e(
          'Not connected to any device or selected device is null. Selected device: $_selectedDevice, isConnected: ${_bluetoothService.isConnected}');
      return false;
    }

    logger.i('Sending single line to device: ${_selectedDevice!.name}');
    return await _bluetoothService.sendData(line);
  }

  // Discover devices and return a stream
  Stream<BluetoothDeviceModel> startDiscovery() {
    _discoveredDevices.clear();

    return _bluetoothService.startDiscovery().map((device) {
      // Add to list if not already present
      if (!_discoveredDevices.any((d) => d.address == device.address)) {
        _discoveredDevices.add(device);
      }
      return device;
    });
  }

  Future<bool> connectToDeviceByAddress(String address) async {
    if (isConnected) {
      logger.i('Already connected to a device, disconnecting first');
      await disconnect();
    }

    bool connected = await _bluetoothService.connectToDeviceByAddress(address);
    if (connected) {
      // Bağlantı başarılıysa, cihazı al ve _selectedDevice olarak ayarla
      final devices = await getPairedDevices();
      BluetoothDeviceModel? device;
      try {
        device = devices.firstWhere((d) => d.address == address);
      } catch (e) {
        final dummyBluetoothDevice = BluetoothDevice(
          address: address,
          name: "Unknown Device",
          type: BluetoothDeviceType.unknown,
        );
        device = BluetoothDeviceModel.fromBluetoothDevice(dummyBluetoothDevice);
      }
      _selectedDevice = device;

      // Son bağlanılan cihazı kaydet
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lastConnectedDeviceAddress', address);
        await prefs.setString('lastConnectedDeviceName', device!.name);
      } catch (e) {
        logger.e('Error saving last connected device: $e');
      }

      logger.i('Successfully connected to device by address: $address');
      addLogMessage("Bağlantı başarılı: cihaz adresi $address");
    }

    return connected;
  }
}
