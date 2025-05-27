import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothDeviceModel {
  final BluetoothDevice device;
  final bool isConnected;

  BluetoothDeviceModel({
    required this.device,
    this.isConnected = false,
  });

  factory BluetoothDeviceModel.fromBluetoothDevice(BluetoothDevice device, {bool isConnected = false}) {
    return BluetoothDeviceModel(
      device: device,
      isConnected: isConnected,
    );
  }

  String get address => device.address;
  bool get isBonded => device.isBonded;
  String get name => device.name ?? 'Unknown Device';
  BluetoothDeviceType get type => device.type;
}
