import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:makine/logger.dart';
import 'package:makine/model/bluetooth_device_model.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  bool _isConnected = false;

  // Stream controller for receiving messages
  Stream<String>? _dataStream;

  // Getter for the Bluetooth instance
  FlutterBluetoothSerial get bluetooth => _bluetooth;

  BluetoothConnection? get connection => _connection;

  // Getter for the connected state
  bool get isConnected => _isConnected;

  // Connect to a device
  Future<bool> connectTooDevice(BluetoothDeviceModel device) async {
    try {
      // Disconnect from previous connection if exists
      if (_isConnected || _connection != null) {
        logger.i('Already connected, disconnecting first');
        await disconnect();
      }

      logger.i('Connecting to device: ${device.name} (${device.address})');

      // Add timeout to the connection attempt
      _connection = await BluetoothConnection.toAddress(device.address).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          logger.e('Connection timeout for device: ${device.name}');
          throw TimeoutException('Connection timeout');
        },
      );

      logger.i('Connection established, checking if it\'s valid');

      if (_connection != null && _connection!.isConnected) {
        _isConnected = true;

        // Set up data stream
        _dataStream = _connection!.input!.map((Uint8List data) {
          return utf8.decode(data);
        });

        logger.i('Successfully connected to ${device.name}');

        // Test connection by sending a small ping
        try {
          logger.i('Testing connection with ping');
          _connection!.output.add(Uint8List.fromList(utf8.encode('\r\n')));
          await _connection!.output.allSent;
          logger.i('Ping test successful');
        } catch (e) {
          logger.e('Ping test failed: $e');
          // Don't fail the connection just because ping failed
        }

        return true;
      } else {
        logger.e('Connection object created but isConnected is false');
        _isConnected = false;
        _connection = null;
        return false;
      }
    } catch (e) {
      logger.e('Error connecting to device: $e');
      _isConnected = false;
      _connection = null;
      return false;
    }
  }

  // Disconnect from device
  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
    _isConnected = false;
    logger.i('Disconnected from device');
  }

  // Get bonded (paired) devices
  Future<List<BluetoothDeviceModel>> getBondedDevices() async {
    try {
      List<BluetoothDevice> bondedDevices = await _bluetooth.getBondedDevices();
      return bondedDevices.map((device) => BluetoothDeviceModel.fromBluetoothDevice(device)).toList();
    } catch (e) {
      logger.e('Error getting bonded devices: $e');
      return [];
    }
  }

  // Get stream of data from device
  Stream<String>? getDataStream() {
    return _dataStream;
  }

  // Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    return await _bluetooth.isEnabled ?? false;
  }

  // Request to enable Bluetooth
  Future<bool> requestEnable() async {
    return await _bluetooth.requestEnable() ?? false;
  }

  // Request Bluetooth permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    logger.i('Bluetooth permission: ${statuses[Permission.bluetooth]}');
    logger.i('Bluetooth Connect permission: ${statuses[Permission.bluetoothConnect]}');
    logger.i('Bluetooth Scan permission: ${statuses[Permission.bluetoothScan]}');
    logger.i('Location permission: ${statuses[Permission.location]}');

    return statuses.values.every((status) => status.isGranted);
  }

  // Send data to the connected device
  Future<bool> sendData(String data) async {
    if (!_isConnected || _connection == null) {
      logger.e('Cannot send data: Not connected to any device or connection is null');
      return false;
    }

    try {
      logger.i('Attempting to send data: $data');
      _connection!.output.add(Uint8List.fromList(utf8.encode('$data\r\n')));
      await _connection!.output.allSent;
      logger.i('Successfully sent data: $data');
      return true;
    } catch (e) {
      logger.e('Error sending data: $e');

      // Check if the error is due to connection being closed
      if (e.toString().contains('closed') || e.toString().contains('not connected')) {
        _isConnected = false;
        _connection = null;
        logger.e('Connection appears to be closed, updating connection state to false');
      }

      return false;
    }
  }

  // Send multiple GCode lines to the device with delay
  Future<bool> sendGCodeLines(List<String> lines, int delayMs) async {
    if (!_isConnected || _connection == null) {
      logger.e('Cannot send GCode lines: Not connected to any device or connection is null');
      return false;
    }

    try {
      bool success = true;
      int total = lines.length;
      int processed = 0;

      logger.i('Starting to send ${lines.length} GCode lines with delay: $delayMs ms');

      for (String line in lines) {
        if (line.isNotEmpty) {
          bool sent = await sendData(line);
          if (!sent) {
            success = false;
            logger.e('Failed to send line: $line');
            break; // Stop on first error
          }

          processed++;
          logger.i('Sent line $processed/$total: $line');

          // Wait for the specified delay before sending the next line
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }

      logger.i('Completed sending GCode lines. Success: $success, Processed: $processed/$total');
      return success;
    } catch (e) {
      logger.e('Error sending GCode lines: $e');
      return false;
    }
  }

  // Discover devices
  Stream<BluetoothDeviceModel> startDiscovery() {
    try {
      return _bluetooth.startDiscovery().map((result) => BluetoothDeviceModel.fromBluetoothDevice(result.device));
    } catch (e) {
      logger.e('Error discovering devices: $e');
      return Stream.empty();
    }
  }

  Future<bool> connectToDeviceByAddress(String address) async {
    try {
      // BluetoothDevice nesnesini oluştur
      final BluetoothDevice device = BluetoothDevice(
        address: address,
        name: "Unknown", // Adı başlangıçta bilinmiyor olabilir
        type: BluetoothDeviceType.unknown,
      );

      // Bağlantıyı kur
      BluetoothConnection connection = await BluetoothConnection.toAddress(address);
      _connection = connection;

      // Eğer bağlantı kurulduysa, cihaz hakkında daha fazla bilgi edinebilirsiniz
      if (connection.isConnected) {
        // Bağlantı kurulduktan sonra cihaz bilgilerini güncelle
        _dataStream = connection.input?.asBroadcastStream().map((Uint8List data) {
          return utf8.decode(data);
        });
        _isConnected = true;
        return true;
      }
      return false;
    } catch (e) {
      logger.e('Error connecting to device by address: $e');
      _isConnected = false;
      _connection = null;
      return false;
    }
  }
}
